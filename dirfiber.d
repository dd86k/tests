import std.stdio;
import std.getopt;
import std.file;
import std.conv : to;
import std.algorithm.sorting;
import std.datetime;
import std.datetime.stopwatch;
import std.concurrency;
import std.parallelism;
import core.thread;
import core.thread.fiber;
import core.memory;

//immutable Duration timeout = 10.usecs; //1.msecs;

struct Test
{
    string name;
    void function(string,Duration) fn;
    Duration time;
    GC.Stats gc0;
    GC.Stats gc1;
}

int main(string[] args)
{
    Duration timeout = 10.usecs;
    GetoptResult res = void;
    try res = getopt(args,
        "msecs", "", (string _, string v) {
            timeout = dur!"msecs"(to!long(v));
        },
    );
    catch (Exception ex)
    {
        stderr.writeln("error: ", ex.msg);
        return 1;
    }
    
    if (args.length <= 1)
    {
        stderr.writeln("Give me a directory");
        return 1;
    }
    
    string dir = args[1];
    
    if (isDir(dir) == false)
    {
        stderr.writeln("I said, give me a directory");
        return 1;
    }
    
    writeln("Thread.sleep: ", timeout);
    
    Test[] tests = [
        { "(Control) Normal iterator", &testNormal },
        { "(Test A) Unconditionally-spawn model", &testA },
        { "(Test B) Parallel(1) model", &testB },
        { "(Test C) Parallel(4) model", &testC },
        { "(Test D) Message-blocking(4) model", &testD },
        { "(Test E) Message-throw(4) model", &testE },
        { "(Test F) Producer-consumer(4) model", &testF },
    ];
    
    // TODO: GC metrics
    foreach (ref test; tests)
    {
        bench(test, dir, timeout);
    }
    writeln;
    writeln("Results (sleep: ", timeout, "):");
    int i;
    foreach (ref result; tests.sort!"a.time < b.time"())
    {
        SimpleDuration sd = simplerDuration(result.time);
        writefln("%2d. %4d %2s, %s", ++i, sd.base, sd.unit, result.name);
        
        writefln("%15s used=%dK",
            "GC",
            (result.gc1.usedSize - result.gc0.usedSize) / 1024
        );
    }
    return 0;
}

struct SimpleDuration
{
    ulong base;
    string unit;
}
SimpleDuration simplerDuration(Duration d)
{
    // NOTE: static immutable does avoid recreating Duration instances
    //       but for the sake of testing, this is pointless
    if (d >= 1.seconds)
        return SimpleDuration(d.total!"seconds"(), "s");
    if (d >= 1.msecs)
        return SimpleDuration(d.total!"msecs"(), "ms");
    if (d >= 1.usecs)
        return SimpleDuration(d.total!"usecs"(), "µs");
    if (d >= 1.hnsecs)
        return SimpleDuration(d.total!"hnsecs"(), "hn");
    return SimpleDuration(d.total!"nsecs"(), "ns");
}

// NOTE: There is a function called benchmark
void bench(ref Test test, string dir, Duration timeout)
{
    writeln("Testing: ", test.name);
    
    GC.collect();
    test.gc0 = GC.stats();
    
    StopWatch sw;
    sw.start();
    test.fn(dir, timeout);
    sw.stop();
    
    test.gc1 = GC.stats();
    test.time = sw.peek();
}
void sleepnow(ref DirEntry entry, Duration timeout)
{
    //writeln("entry: ", entry.name);
    Thread.sleep(timeout);
}

// Test: Normal
// NOTE: Your typical, single-thread loop.
//       This is the baseline.
void testNormal(string path, Duration timeout)
{
    foreach (entry; dirEntries(path, SpanMode.breadth))
    {
        sleepnow(entry, timeout);
    }
}

// Test: Naively spawn concurrent threads
// NOTE: Naive because, if you have a million files, this will
//       spawn a million threads.
//       This becomes slower the number of entries increase.
void testA(string path, Duration timeout)
{
    foreach (entry; dirEntries(path, SpanMode.breadth))
    {
        spawn(&iterateConcurrentEntry, entry, timeout);
    }
}
void iterateConcurrentEntry(DirEntry entry, Duration timeout)
{
    sleepnow(entry, timeout);
}

// Test: parallel with one task per thread
void testB(string path, Duration timeout)
{
    foreach (entry; parallel(dirEntries(path, SpanMode.breadth), 1))
    {
        sleepnow(entry, timeout);
    }
}

// Test: parallel with eight tasks per thread
// NOTE: The bottleneck is introduced by dirEntries
//       parallel wants to fill 8 tasks for the thread, but has
//       to wait for the next iteration from dirEntries, introducing
//       stalling
void testC(string path, Duration timeout)
{
    foreach (entry; parallel(dirEntries(path, SpanMode.breadth), 4))
    {
        sleepnow(entry, timeout);
    }
}

// Test: Message-based method with a manually-created thread pool
void testD(string path, Duration timeout)
{
    enum POOLSIZE = 4;
    scope pool = new Tid[POOLSIZE];
    for (size_t i; i < POOLSIZE; ++i)
    {
        Tid tid = spawn(&testDWorker, thisTid);
        setMaxMailboxSize(tid, 10, OnCrowding.block);
        pool[i] = tid;
    }
    
    size_t cur;
    foreach (entry; dirEntries(path, SpanMode.breadth))
    {
        send(pool[cur++], MsgEntry(entry, timeout));
        if (cur >= POOLSIZE) cur = 0;
    }
    
    // NOTE: Usually you'd want your replies back
    //       to your parent thread or in a similar fashion
    
    foreach (ref tid; pool)
    {
        send(tid, MsgClose());
    }
    foreach (ref tid; pool)
    {
        receiveOnly!MsgCloseAck;
    }
}
struct MsgEntry
{
    DirEntry entry;
    Duration timeout;
}
//struct MsgResult {}
struct MsgClose {}
struct MsgCloseAck {}
void testDWorker(Tid parentId)
{
    bool working = true;
    while (working)
    {
        receive(
            (MsgEntry entry) {
                sleepnow(entry.entry, entry.timeout);
            },
            (MsgClose creq) {
                send(parentId, MsgCloseAck());
                working = false;
            }
        );
    }
}

// 
void testE(string path, Duration timeout)
{
    enum POOLSIZE = 4;
    scope pool = new Tid[POOLSIZE];
    for (size_t i; i < POOLSIZE; ++i)
    {
        Tid tid = spawn(&testEWorker, thisTid);
        setMaxMailboxSize(tid, 10, OnCrowding.throwException);
        pool[i] = tid;
    }
    
    size_t cur;
    foreach (entry; dirEntries(path, SpanMode.breadth))
    {
        try send(pool[cur], MsgEntry(entry, timeout));
        catch (MailboxFull) {} // try next
        if (++cur >= POOLSIZE) cur = 0;
    }
    
    // NOTE: Usually you'd want your replies back
    //       to your parent thread or in a similar fashion
    
    foreach (ref tid; pool)
    {
        setMaxMailboxSize(tid, 10, OnCrowding.block);
        send(tid, MsgClose());
    }
    foreach (ref tid; pool)
    {
        receiveOnly!MsgCloseAck;
    }
}
void testEWorker(Tid parentId)
{
    bool working = true;
    while (working)
    {
        receive(
            (MsgEntry entry) {
                sleepnow(entry.entry, entry.timeout);
            },
            (MsgClose creq) {
                send(parentId, MsgCloseAck());
                working = false;
            }
        );
    }
}

void testF(string path, Duration timeout)
{
    Tid queuer = spawn(&testSynchronizedQueuer);
    //setMaxMailboxSize(queuer, 4, OnCrowding.block);
    foreach (entry; dirEntries(path, SpanMode.breadth))
    {
        send(queuer, Msg2Entry(entry, timeout));
    }
    send(queuer, Msg2Done());
}
struct Msg2Entry { DirEntry entry; Duration timeout; }
struct Msg2Done {}
void testSynchronizedQueuer()
{
    bool working = true;
    while (working)
    {
        receive(
            (Msg2Entry entry) {
                spawn(&testSynchronizedWorker, entry.entry, entry.timeout);
            },
            (Msg2Done done) {
                working = false;
            }
        );
    }
}
void testSynchronizedWorker(DirEntry entry, Duration timeout)
{
    sleepnow(entry, timeout);
}
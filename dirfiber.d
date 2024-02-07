import std.stdio;
import std.file;
import std.algorithm.sorting;
import std.datetime;
import std.datetime.stopwatch;
import std.concurrency;
import std.parallelism;
import core.thread;
import core.thread.fiber;

immutable Duration timeout = 10.usecs; //1.msecs;

struct Test
{
    void function(string) fn;
    string name;
    Duration time;
}

struct SimpleDuration
{
    ulong base;
    string unit;
}

void main(string[] args)
{
    if (args.length <= 1)
    {
        stderr.writeln("Give me a directory");
        return;
    }
    
    string dir = args[1];
    
    if (isDir(dir) == false)
    {
        stderr.writeln("I said, give me a directory");
        return;
    }
    
    writeln("Thread.sleep: ", timeout);
    
    Test[] tests = [
        { &testNormal,          "Normal iterator" },
        { &testConcurrent,      "Naive-Concurrent iterator" },
        { &testParallel1,       "Parallel(1) iterator" },
        { &testParallel8,       "Parallel(8) iterator" },
        { &testMessages8,       "Message-based(8) iterator" }
    ];
    
    write("Performing ", tests.length, " tests");
    foreach (ref test; tests)
    {
        write(".");
        stdout.flush();
        bench(test, dir);
    }
    writeln;
    writeln("Results:");
    int i;
    foreach (ref result; tests.sort!"a.time < b.time"())
    {
        SimpleDuration sd = simplerDuration(result.time);
        writefln("%2d. %10d %s %s", ++i, sd.base, sd.unit, result.name);
    }
}

SimpleDuration simplerDuration(Duration d)
{
    static immutable Duration second = 1.seconds;
    if (d >= second)
        return SimpleDuration(d.total!"seconds"(), "s ");
    
    static immutable Duration millisecond = 1.msecs;
    if (d >= millisecond)
        return SimpleDuration(d.total!"msecs"(), "ms");
    
    static immutable Duration microsecond = 1.usecs;
    if (d >= microsecond)
        return SimpleDuration(d.total!"usecs"(), "µs");
    
    static immutable Duration hectonanosecond = 1.hnsecs;
    if (d >= hectonanosecond)
        return SimpleDuration(d.total!"hnsecs"(), "hn");
    
    return SimpleDuration(d.total!"nsecs"(), "ns");
}

// NOTE: There is a function called benchmark
void bench(ref Test test, string dir)
{
    StopWatch sw;
    sw.start();
    test.fn(dir);
    sw.stop();
    test.time = sw.peek();
}
void sleepnow()
{
    Thread.sleep(timeout);
}

// Test: Normal
// NOTE: Your typical, single-thread loop.
//       This is the baseline.
void testNormal(string path)
{
    foreach (entry; dirEntries(path, SpanMode.breadth))
    {
        sleepnow();
    }
}

// Test: Naively spawn concurrent threads
// NOTE: Naive because, if you have a million files, this will
//       spawn a million threads.
//       This becomes slower the number of entries increase.
void testConcurrent(string path)
{
    foreach (entry; dirEntries(path, SpanMode.breadth))
    {
        spawn(&iterateConcurrentEntry, entry);
    }
}
void iterateConcurrentEntry(DirEntry entry)
{
    sleepnow();
}

// Test: parallel with one task per thread
void testParallel1(string path)
{
    foreach (entry; parallel(dirEntries(path, SpanMode.breadth), 1))
    {
        sleepnow();
    }
}

// Test: parallel with eight tasks per thread
// NOTE: The bottleneck is introduced by dirEntries
//       parallel wants to fill 8 tasks for the thread, but has
//       to wait for the next iteration from dirEntries, introducing
//       stalling
void testParallel8(string path)
{
    foreach (entry; parallel(dirEntries(path, SpanMode.breadth), 8))
    {
        sleepnow();
    }
}

// Test: Message-based method with a threadpool of 8
void testMessages8(string path)
{
    enum POOLSIZE = 8;
    scope pool = new Tid[POOLSIZE];
    for (size_t i; i < POOLSIZE; ++i)
    {
        Tid tid = spawn(&conWorker, thisTid);
        setMaxMailboxSize(tid, 10, OnCrowding.block);
        pool[i] = tid;
    }
    
    size_t cur;
    foreach (entry; dirEntries(path, SpanMode.breadth))
    {
        send(pool[cur++], MsgEntry(entry.name));
        if (cur >= POOLSIZE) cur = 0;
    }
    
    // NOTE: Usually you'd want your replies back
    //       to your parent thread or in a similar fashion
    
    foreach (ref tid; pool)
    {
        send(tid, MsgCloseReq());
    }
    // NOTE: Not necessary in this case, but usually needed
    //foreach (ref tid; pool)
    //{
    //    receiveOnly!MsgCloseAck;
    //}
}
struct MsgEntry
{
    this(string e) { name = e; }
    string name;
}
struct MsgResult
{
    
}
struct MsgCloseReq
{
    
}
struct MsgCloseAck
{
    
}
void conWorker(Tid parentId)
{
    bool cont = true;
    while (cont)
    {
        receive(
            (MsgEntry entry) {
                sleepnow();
                //send(parentId, MsgResult());
            },
            (MsgCloseReq creq) {
                send(parentId, MsgCloseAck());
                cont = false;
            }
        );
    }
}


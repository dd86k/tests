import core.memory;
import core.thread;
import std.algorithm.sorting;
import std.concurrency;
import std.conv : to;
import std.datetime;
import std.datetime.stopwatch;
import std.file;
import std.getopt;
import std.parallelism;
import std.stdio;

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
        "msecs", "Set timer sleep duration in milliseconds",
            (string _, string v) {
                timeout = dur!"msecs"(to!long(v));
            },
    );
    catch (Exception ex)
    {
        stderr.writeln("error: ", ex.msg);
        return 1;
    }
    
    if (res.helpWanted)
    {
        defaultGetoptPrinter("Multithread tests", res.options);
        return 0;
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
        { "(Test G) SPMC Queue(4) model", &testG },
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
        writefln("%2d. %10.3f %-2s, %s", ++i, sd.base, sd.unit, result.name);
        
        writefln("%21s used=%dK",
            "GC",
            (result.gc1.usedSize - result.gc0.usedSize) / 1024
        );
    }
    return 0;
}

struct SimpleDuration
{
    double base;
    string unit;
}
SimpleDuration simplerDuration(Duration d)
{
    // NOTE: static immutable does avoid recreating Duration instances
    //       but for the sake of testing, this is pointless
    if (d >= 1.seconds)
        return SimpleDuration(d.total!"msecs"() / 1000.0, "s");
    if (d >= 1.msecs)
        return SimpleDuration(d.total!"usecs"() / 1000.0, "ms");
    if (d >= 1.usecs)
        return SimpleDuration(d.total!"nsecs"() / 1000.0, "µs");
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
void dowork(ref DirEntry entry, Duration timeout)
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
        dowork(entry, timeout);
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

    thread_joinAll();
}
void iterateConcurrentEntry(DirEntry entry, Duration timeout)
{
    dowork(entry, timeout);
}

// Test: parallel with one task per thread
void testB(string path, Duration timeout)
{
    foreach (entry; parallel(dirEntries(path, SpanMode.breadth), 1))
    {
        dowork(entry, timeout);
    }

    thread_joinAll();
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
        dowork(entry, timeout);
    }

    thread_joinAll();
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

    thread_joinAll();
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
                dowork(entry.entry, entry.timeout);
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
        bool sent = false;
        while (!sent)
        {
            try
            {
                send(pool[cur], MsgEntry(entry, timeout));
                sent = true;
            }
            catch (MailboxFull) {} // try next
            if (++cur >= POOLSIZE) cur = 0;
        }
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

    thread_joinAll();
}
void testEWorker(Tid parentId)
{
    bool working = true;
    while (working)
    {
        receive(
            (MsgEntry entry) {
                dowork(entry.entry, entry.timeout);
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

    thread_joinAll();
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
    dowork(entry, timeout);
}

// Some theory first: we assume that (1) communication between the sides
// isn't very chatty, and (2) the consumers are, on average, heavier than
// the producers. In this case, having a global queue is the most optimal
// strategy, since it allows each consumer to have access to all
// currently-available jobs.
// Unfortunately D stdlib doesn't seem to include an implementation of a
// thread-safe queue, so we need to implement one ourselves.

import core.sync.condition;
import core.sync.mutex;
import core.thread.osthread;

// Simple concurrent queue implementation akin to those available in Go or Java.
// Could probably use some more optimization.
class QueueClosedException: Exception { this() { super("Queue is closed"); } }
class ConcurrentQueue(T)
{
    private T[]    elements;
    private size_t head, tail, cap;
    private bool   isClosed;

    // For synchronization.
    Mutex     mutex;
    Condition cblock; // Signals whether a consumer is blocked.
    Condition pblock; // Signals whether a producer is blocked.

    /// Construct a queue of capacity `cap`.
    /// For best performance, it is recommened for `cap` to be a compile-time constant
    /// that is a power of two.
    this(size_t cap)
    {
        if (cap < 2)
            throw new Exception("cap too small, need at least 2!");
        elements = new T[cap];
        head = tail = 0;
        this.cap = cap;
        isClosed = false;

        mutex = new Mutex;
        cblock = new Condition(mutex);
        pblock = new Condition(mutex);
    }

    private shared bool isEmpty()
    {
        synchronized (mutex)
        {
            return head == tail;
        }
    }

    private shared bool isFull()
    {
        synchronized (mutex)
        {
            return (tail+1) % cap == head;
        }
    }

    /// Push an item to the queue.
    /// This will block if the queue is full.
    shared void push(T value)
    {
        synchronized (mutex)
        {
            if (isClosed)
                throw new QueueClosedException();

            while (isFull())
            {
                // The queue is full, so block to let the consumers run.
                pblock.wait();
            }

            // BUG: Compiler would complain about Msg3Entry not having an assignment operator
            //elements[tail] = value;
            import core.stdc.string : memcpy;
            memcpy(cast(void*)(elements.ptr + tail), &value, T.sizeof);
            tail = (tail+1) % cap;
        }

        // Unblock a consumer.
        cblock.notify();
    }

    /// Pop an item from the queue.
    /// This will block if the queue is empty.
    shared T pop()
    {
        synchronized (mutex)
        {
            while (isEmpty())
            {
                if (isClosed)
                    throw new QueueClosedException();
                // The queue is empty, so block to let the producers run.
                cblock.wait();
            }

            // Unblock a producer.
            pblock.notify();
            head = (head+1) % cap;
            return cast(T) elements[head];
        }
    }

    /// This simply blocks until all the elements have been drained.
    shared void waitForDrain()
    {
        synchronized (mutex)
        {
            while(!isEmpty())
                pblock.wait();
        }
    }

    /// Closes the queue, signalling that no more items will be pushed.
    /// This still allows existing items to be drained off the queue.
    shared void close()
    {
        synchronized (mutex)
        {
            isClosed = true;
        }

        // Unblock both sides of the queue.
        cblock.notifyAll();
        pblock.notifyAll();
    }
}

// Now that the queue is set up, the actual processing part is pretty simple.
struct Msg3Entry { DirEntry entry; Duration timeout; }
void testG(string path, Duration timeout)
{
    // Single producer, multple consumer (SPMC) queue.
    // Now that we only have a single queue, we can afford to make it bigger
    // to minimize blocking.
    shared ConcurrentQueue!(Msg3Entry) rqsd = new shared ConcurrentQueue!(Msg3Entry)(32);

    // Just like with testE, we use a thread pool to avoid excessive
    // thread creation/destruction overhead.
    enum POOLSIZE = 4;
    for (size_t i; i < POOLSIZE; ++i)
    {
        spawn(&testQueueConsumer, rqsd);
    }

    // Now that the thread pool is set up the only thing this thread needs
    // to do is to just push data to the queue.
    foreach (entry; dirEntries(path, SpanMode.breadth))
    {
        rqsd.push(Msg3Entry(entry, timeout));
    }

    // After we're done pushing, close it to signal the end of transmission.
    rqsd.close();

    thread_joinAll();
}

void testQueueConsumer(shared ConcurrentQueue!(Msg3Entry) queue)
{
    // The consumer side simply needs to keep popping things
    // off the queue until it is closed.
    while (true)
    {
        try
        {
            Msg3Entry value = queue.pop();
            dowork(value.entry, value.timeout);
        }
        catch (QueueClosedException)
        {
            return;
        }
    }
}

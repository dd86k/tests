Contains a set of quick D scripts.

You can run these using `rdmd` or with `dmd -run`/`ldc2 -run`/`gdmd`/`ldmd2`.

I use them on various platforms, seeing given different compiler configurations, etc.

Very useful scripts are `versions.d` and `features.d`.

| Script | Description |
|---|---|
| windows/fpu.d | Attempt to use MSVC specific features. |
| aa.d | Associated Array (aka HashMap, Dictionary) tests. |
| cstreams.d | Re-opens the standard output stream, due to it being broken on Windows-betterC. |
| dirfiber.d | Benchmark of various implementations of a multi-threaded `dirEntries`. |
| features.d | Prints available compiler features. |
| fetch.d | Using `requests`, fetch content via HTTP. |
| floats.d | Quick float comparison and printing test. |
| formatdec.d | Format decimal precision test. |
| formathex.d | Tried out the printf `%#` specifier. |
| gen24.d | Family member required a text file in a format. |
| json.d | Quick `std.json` tests. |
| minimal.d | Smallest D source. |
| randommangle.d | Randomly generate a mangled name, works with exports. |
| strings.d | Quick string printing test. |
| tokens.d | Print special tokens and keywords. |
| types.d | Print type information. |
| version.d | Print what compiler pre-defined versions are available. |
| wave.d | Fun moving 0's and 1's. |
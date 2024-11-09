Contains a set of quick D scripts for testing purposes.

I use them on various platforms to see their effect on different
platforms, compilers, settings, etc.

The most useful ones being `versions.d` and `features.d`.

You can run these individually using
`rdmd`, `gdmd`, `ldmd2`, `dmd -run`, or `ldc2 -run`.

e.g., `rdmd features.d`

| Script | Description |
|---|---|
| windows/fpu.d | Attempt to use MSVC specific features. |
| aa.d | Associated Array (aka HashMap, Dictionary) tests. |
| cstreams.d | Re-opens the standard output stream, due to it being broken on Windows-betterC. (NOTE: Not anymore!) |
| dirfiber.d | Benchmark of various implementations of a multi-threaded `dirEntries`. |
| features.d | Prints available compiler features. |
| fetch.d | Using `requests` package (DUB), fetch content via HTTP. |
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
| versions.d | Print pre-defined compiler versions available. |
| stdio.d | Read line and print its content per byte. |
| wave.d | Fun moving 0's and 1's. |
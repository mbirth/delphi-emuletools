eMule-Tools
===========

GapRemover
----------

Syntax: `GapRemover <infile> <outfile>`


GapRemover parses `<infile>` in 64Bytes-Blocks.
Those blocks are copied into `<outfile>` if they contain anything other than 00h-Bytes.

I wrote this because my Media Player keeps freezing when there are errors in the stream.
This procedure keeps the freezes short.


GapMerger
---------

Syntax: `GapMerger <infile1> <infile2> <outfile>`


GapRemover parses both `<infilex>`s in 64Bytes-Blocks.
It copies `<infile1>` to `<outfile>` except if a byte in `<infile1>` is 00h and the byte at the same position in `<infile2>` is NOT 00h.
Then, the byte from `<infile2>` is written into `<outfile>`.

`<infile1>` and `<infile2>` have to be same size.


I wrote this because I sometimes download the same file 2 times and both downloads have gaps at different parts of the file.
This tool merges all data into one file.

GapRemover for eMule
====================

Syntax: `GapRemover <infile> <outfile>`


GapRemover parses `<infile>` in 64Bytes-Blocks.
Those blocks are copied into `<outfile>` if they contain anything other than 00h-Bytes.

I wrote this because my Media Player keeps freezing when there are errors in the stream.
This procedure keeps the freezes short.

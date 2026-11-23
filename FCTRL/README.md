## Problem

For each of about 100000 queries a positive integer n up to 10^9 is given. Print
how many zeros appear at the end of n! in decimal.

## Idea

A trailing zero needs a factor pair 2 and 5. A factorial always has more twos than
fives, so the answer is just the number of fives inside n!, which is n/5 + n/25
plus every higher power of five that still fits.

## Why It Works

Every multiple of 5 contributes one factor 5, every multiple of 25 contributes a
second one, and so on, so summing the integer divisions n div 5^k counts all
factors of five exactly once each. Twos are plentiful: each block of five
consecutive factors contains at least one even number, so twos can never be the
limiting factor. The sum has only about 13 terms for n up to 10^9, so each query
is essentially free; the run is dominated by reading and writing, which is why
input is slurped line by line and output is emitted in large blocks.

## Code

`solution.nim`

## Complexity

Per query the work is O(log n) with O(1) memory, so the whole run is O(T log n)
time and O(1) extra memory beyond the output buffer.

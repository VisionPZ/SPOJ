## Problem

The first line gives the number of cases. Each case is one line with two positive
integers that are already written reversed. Add the two reversed numbers and print
the result again reversed, with any leading zeros dropped.

## Idea

Reverse a number means reading its digits backwards, so adding two reversed numbers
is the same as adding their digit strings from left to right. The reversed sum is
then just that digit list printed from the low end, skipping zeros at the front.

## Why It Works

The digits of a reversed number appear in the order the judge wrote them, so the
first character of a token is its least significant digit. Schoolbook addition with
a carry therefore builds the sum with its least significant digit first. Printing
that list in order reverses the sum, and dropping the zeros at the front of the
printed string removes leading zeros, exactly as required. Spurious zeros at the
high end are trimmed first so a sum like 2 never prints as 20. Values can be far
longer than 64 bits, so digit strings avoid overflow entirely. Input is read line
by line and output is written in large blocks, keeping the run IO bound on the
judge.

## Code

`solution.nim`

## Complexity

Per case the work is linear in the number of digits, so the whole run is O(total
digits) time and O(max digits) memory.

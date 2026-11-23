## Problem

Up to 100 test cases ask for n! with n between 1 and 100. The answers are far too
big for any machine integer, so each result must be printed exactly, up to 158
digits.

## Idea

Build the factorial table once, from 0! to 100!, storing each number as a list of
base 10^9 limbs. Then answer each query by printing the stored limbs, padding every
limb but the most significant one to nine digits.

## Why It Works

Multiplying a limb list by the small factor k uses schoolbook arithmetic with a
carry, and one limb times 100 stays far below 2^63, so no overflow can happen.
Keeping nine decimal digits per limb keeps the lists short (18 limbs for 100!) and
makes printing cheap: the top limb prints as is, and every lower limb needs its
leading zeros restored, which is why the padding loop exists. Precomputing means
the whole run does 100 multiplications regardless of the query order or count.

## Code

`solution.nim`

## Complexity

Precomputation costs O(sum of digits of n!) which is tiny (a few thousand limb
operations); each query prints O(digits) output. Memory is O(digits of 100!) for
the table.

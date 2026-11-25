# MLLOVE — Masud and Layla love story (SPOJ)
<https://www.spoj.com/problems/MLLOVE/>

## Problem

Sum the distinct prices found on an infinite arithmetic walk through indices modulo n.

The input has two integers n and k.
Layla visits indices 1, 1+k, 1+2k and so on without end.
The price at an index is that index modulo n.
Prices are counted once even when visited many times.
Output one integer: the sum of all distinct prices.

| item | bound |
|---|---|
| n | 1 to 1000000000 |
| k | 1 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

The walk is infinite, but prices can only be residues from 0 to n-1.

Sample input:

```
6 3
```

Sample output:

```
5
```

## Idea

The repeated step only reaches residues spaced by the greatest common divisor, like clock ticks that land on every third mark.

Let g be the greatest common divisor of n and k.
The walk visits prices 1, 1+g, 1+2g and so on modulo n.
There are n/g distinct prices.
They form a short arithmetic series, so one formula gives the sum.
Walking billions of indices would repeat prices and waste time.

The gcd and one series formula are the whole solution.

## Why It Works

1. Multiples of k modulo n are exactly the multiples of g modulo n.
2. Adding 1 shifts those residues by one.
3. When g is 1 every residue appears, and the sum is n(n-1)/2.
4. When g is greater than 1 the prices 1, 1+g and so on never wrap past n.

| term | meaning |
|---|---|
| `moduloBase` | the modulus n |
| `visitStride` | the step k |
| `commonStep` | the greatest common divisor of n and k |
| `distinctCount` | the number of distinct prices |

For the sample n is 6 and k is 3, so g is 3.
The prices are 1 and 4, and their sum is 5.

## Code

**Input, scanning and gcd.** The reader loads both values and finds their common step.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

proc gcdValues(firstValue, secondValue: int64): int64 =
  var larger = firstValue
  var smaller = secondValue
  while smaller != 0:
    let remainder = larger mod smaller
    larger = smaller
    smaller = remainder
  return larger
```

The gcd loop shrinks the pair until one value is zero.
The scanner keeps both values in int64.

**Series sum and output.** The two cases produce the sum without a walk.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let moduloBase = nextInt(inputData, scanPos)
let visitStride = nextInt(inputData, scanPos)
let commonStep = gcdValues(moduloBase, visitStride)
var totalCost: int64 = 0
if commonStep == 1:
  totalCost = moduloBase * (moduloBase - 1) div 2
else:
  let distinctCount = moduloBase div commonStep
  totalCost = distinctCount + commonStep * distinctCount * (distinctCount - 1) div 2

appendOutput($totalCost)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The product of consecutive counts is even, so the division is exact.
The single answer is flushed once.

## Complexity

The gcd loop is the only repeated work.

| phase | time | space |
|---|---|---|
| input read | two integers | one input string |
| gcd and sum | a few division steps | a few integers |
| output | one line | block buffer |

| measure | Big O |
|---|---|
| time | O(log n) |
| space | O(1) |

Walking every visit would need up to 10^18 steps instead of a short gcd loop.

The series formula returns the exact sum for every allowed pair.

# CSETB — Count Set Bits (SPOJ)

<https://www.spoj.com/problems/CSETB/>

## Problem

Given several numbers, report for each one how many `1` bits appear in all binary forms from 1 up to that number.

The input starts with the test count. Each following line holds one number. Print one total per line.

| item | bound |
|---|---|
| tests t | 1 to 20 |
| number n | 1 to 10000 |
| judge limit | 1000 ms, 1536 MB |

The largest n fixes how far the one-pass table must reach.

Sample input:

```
5
7
4
10
9
6
```

Sample output:

```
12
5
17
15
9
```

## Idea

Count lit bulbs row by row, like tallying lamps that switch on as a row of counters climbs. Build two tables once, then answer each test with one lookup. A bit count for n uses the count for n divided by two, so each step costs one division and one addition. Recounting every number for every test repeats the same work and costs far more. One shared table answers all tests at constant cost each.

## Why It Works

1. Halving a number shifts its binary form one place right.
2. The set bits of n equal the set bits of n halved, plus the last bit of n.
3. A running total adds each new bit count to every total before it.
4. The total at position n is exactly the sum of bit counts from 1 to n.

| term | meaning |
|---|---|
| `bitCounts` | set bits in the binary form of one number |
| `prefixCounts` | set bits summed over all numbers up to an index |
| `limitNumber` | largest number asked by any test |

The table grows once to the largest requested number.

Script-generated trace for the numbers up to seven:

```
numberValue | bitCounts | prefixCounts
0 | 0 | 0
1 | 1 | 1
2 | 1 | 2
3 | 2 | 4
4 | 1 | 5
5 | 2 | 7
6 | 2 | 9
7 | 3 | 12
```

The last row gives 12, matching the first sample answer.

## Code

**Bulk input and scanner.** The whole stream is read once, then parsed by a digit scanner.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value
```

All tests are parsed before any table is built.
The scanner skips spaces and line breaks.
Parsing costs one pass over the input bytes.

**Table build and output.** Two sequences fill up to the largest queried number.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
var queries = newSeq[int](caseCount)
var limitNumber = 0
for caseIndex in 0 .. caseCount - 1:
  queries[caseIndex] = nextInt(inputData, scanPos)
  if queries[caseIndex] > limitNumber:
    limitNumber = queries[caseIndex]

var bitCounts = newSeq[int](limitNumber + 1)
var prefixCounts = newSeq[int](limitNumber + 1)
for numberValue in 1 .. limitNumber:
  bitCounts[numberValue] = bitCounts[numberValue div 2] + (numberValue mod 2)
  prefixCounts[numberValue] = prefixCounts[numberValue - 1] + bitCounts[numberValue]
for caseIndex in 0 .. caseCount - 1:
  appendOutput($prefixCounts[queries[caseIndex]])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each step reads one earlier slot and writes one new slot.
The loop reaches exactly the largest asked number.
Each answer is one lookup and one buffered line.

## Complexity

One table pass serves every test.

| phase | time | space |
|---|---|---|
| input read | one pass over t numbers | one input string |
| table build | one step per number up to largest query | two tables of that size |
| output | one lookup per test | block buffer |

The table costs are paid once, not once per test.

| measure | Big O |
|---|---|
| time | O(t + max n) |
| space | O(max n) |

Recounting bits for every test would cost O(t times n) and repeat identical work.

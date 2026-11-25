# BYTESH1 — Filchs Dilemna (SPOJ)

<https://www.spoj.com/problems/BYTESH1/>

## Problem

Count the ways to cover a path of width two and length N with 1×2 carpets and L-shaped carpets that cover three squares. Both carpet types may rotate. Report the answer modulo 10000, written without leading zeros.

The input starts with the test count `T`, then one path length per line. Output one count per test.

| item | bound |
|---|---|
| test cases T | 1 to 100 |
| path length N | 1 to 1000000 |
| judge limit | 2000 ms, 1536 MB |

A count with fewer than four digits is printed in full.

Sample input:

```
2
3
13
```

Sample output:

```
5
3465
```

## Idea

Build the count from short paths to long ones, like extending a row of fences one post at a time. Each new length needs only three earlier counts.

The algorithm precomputes every answer up to one million using the recurrence `T(n) = 2·T(n−1) + T(n−3)`. Each step costs two additions and one modulo. Trying every carpet arrangement for each N would grow without bound.

One table answers all test cases after a single precompute pass.

## Why It Works

1. A full path of length n ends either with a vertical carpet or with two horizontal carpets or with a pair of L carpets spanning three columns.
2. The two single-carpet endings both leave a full path of length n−1, giving the term `2·T(n−1)`.
3. The paired L ending leaves a full path of length n−3, giving the term `T(n−3)`.
4. The starting values are `T(0)=1`, `T(1)=1`, and `T(2)=2`.
5. Reducing after each step keeps every table entry in the range 0 to 9999.

| term | meaning |
|---|---|
| `tilingCounts` | number of tilings modulo 10000 |
| `maxPathLength` | largest allowed path length |
| `lastDigitsModulus` | modulus that keeps four digits |
| `pathLength` | length read for one test |

Starting from 1, 1, 2, the recurrence gives 5 at length 3 and 13465 at length 13, so the printed value at length 13 is 3465.

Printing the integer value removes any leading zeros automatically.

## Code

**Input and table setup.** The reader loads the test list and prepares the recurrence table.

```nim
const flushBlockBytes = 1 shl 17
const maxPathLength = 1000000
const lastDigitsModulus = 10000

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner reads one length per line.
The modulus keeps intermediate values small.
The buffer collects all answer lines.

**Table fill and lookup.** Each length uses three earlier entries.

```nim
var tilingCounts = newSeq[int](maxPathLength + 1)
tilingCounts[0] = 1
tilingCounts[1] = 1
tilingCounts[2] = 2
for pathLength in 3 .. maxPathLength:
  tilingCounts[pathLength] = (2 * tilingCounts[pathLength - 1] + tilingCounts[pathLength - 3]) mod lastDigitsModulus

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let pathLength = nextInt(inputData, scanPos)
  appendOutput($tilingCounts[pathLength])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop starts at length three.
Each step reads entries n−1 and n−3.
A single final write flushes the output.

## Complexity

The table is built once, then each test is a direct lookup.

| phase | time | space |
|---|---|---|
| input read | one pass over T lengths | one input string |
| table fill | one step per length up to one million | one million entries |
| lookup | constant time per test | constant |
| output | one buffered write | block buffer |

The table fill is the only pass that scales with the length bound.

| measure | Big O |
|---|---|
| time | O(1000000 + T) |
| space | O(1000000) |

Enumerating tilings per test would repeat that work many times. Precomputing once settles every query with one array read.

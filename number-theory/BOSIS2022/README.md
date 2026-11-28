# BOSIS2022 — Números Feos (SPOJ)

<https://www.spoj.com/problems/BOSIS2022/>

## Problem

Ugly numbers use only 2, 3 and 5 as prime factors, and 1 counts as the first one. For each requested rank, print the ugly number at that rank.

The first line holds the number of requests. Each following line holds one rank. Print one ugly number per line, in the same order.

| item | bound |
|---|---|
| request count | 0 to 200 |
| rank | 1 or more |
| largest rank used here | 1500 |
| judge limit | 1000 ms, 1536 MB |

Every ugly number after 1 equals an earlier ugly number multiplied by 2, 3 or 5.

Sample input:

```
5
6
1
4
8
20
```

Sample output:

```
6
1
4
9
36
```

The rank 8 value is 9, because the sequence begins 1, 2, 3, 4, 5, 6, 8, 9.

## Idea

A queue at three ticket counters holds the next candidate from each multiplier; pick the smallest and refill that counter. The algorithm is a three-pointer dynamic program over the ugly sequence. It costs constant work per generated rank. Trial division of every integer would test huge ranges and repeat the same reductions. Read all ranks, generate once up to the largest rank, then answer by table lookup.

## Why It Works

1. Multiply any ugly number by 2, 3 or 5 and the result is ugly.
2. Every ugly number except 1 has one of those three as its largest prime factor.
3. Removing that factor leaves a smaller ugly number already in the table.
4. Three pointers mark the smallest unused product for each multiplier.
5. The smallest of the three products is the next ugly number.

| term | meaning |
|---|---|
| `requestedRanks` | rank asked for by each input line |
| `largestRank` | largest rank in the input |
| `uglyNumbers` | generated sequence, indexed from 1 |
| `pointerTwo` | table index of the next candidate for multiplier 2 |

Each pointer advances past duplicates, so a value such as 6 appears only once in the table.

For the first ranks, the pointer for 2 points at 1 and gives 2. The pointer for 3 gives 3, and the pointer for 5 gives 5. The minimum is 2, so rank 2 is 2. Repeating this gives rank 6 as 6, rank 8 as 9 and rank 20 as 36.

Products grow, so the table uses `int64` values to avoid overflow.

## Code

**Input and scanning.** The reader keeps every rank and finds the largest one.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
var requestedRanks = newSeq[int](caseCount)
var largestRank = 0
for caseIndex in 0 .. caseCount - 1:
  requestedRanks[caseIndex] = nextInt(inputData, scanPos)
  if requestedRanks[caseIndex] > largestRank:
    largestRank = requestedRanks[caseIndex]
```

The largest rank sets the table size.
An empty request list produces no output.
All requests share one generated sequence.

**Sequence build.** Three pointers advance through the same growing table.

```nim
var uglyNumbers = newSeq[int64](largestRank + 1)
if largestRank >= 1:
  uglyNumbers[1] = 1
  var pointerTwo = 1
  var pointerThree = 1
  var pointerFive = 1
  for rankIndex in 2 .. largestRank:
    let nextTwo = uglyNumbers[pointerTwo] * 2
    let nextThree = uglyNumbers[pointerThree] * 3
    let nextFive = uglyNumbers[pointerFive] * 5
    var nextUgly = nextTwo
    if nextThree < nextUgly:
      nextUgly = nextThree
    if nextFive < nextUgly:
      nextUgly = nextFive
    uglyNumbers[rankIndex] = nextUgly
    while uglyNumbers[pointerTwo] * 2 <= nextUgly:
      pointerTwo += 1
    while uglyNumbers[pointerThree] * 3 <= nextUgly:
      pointerThree += 1
    while uglyNumbers[pointerFive] * 5 <= nextUgly:
      pointerFive += 1
```

The minimum product becomes the next rank.
Each while loop removes products already written.
The sequence stays strictly increasing.

**Answer pass.** Each request reads one table slot.

```nim
for caseIndex in 0 .. caseCount - 1:
  if requestedRanks[caseIndex] >= 1:
    appendOutput($uglyNumbers[requestedRanks[caseIndex]])
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Output follows the input order.
Buffered lines are flushed in blocks.
One final flush writes the remainder.

## Complexity

Generating the sequence dominates the run; answering requests is cheap.

| phase | time | space |
|---|---|---|
| input read | one pass over the ranks | rank array |
| sequence build | constant work per rank | generated sequence |
| answer pass | one lookup per request | block output buffer |

| measure | Big O |
|---|---|
| time | O(c + L), for c requests and largest rank L |
| space | O(c + L) |

Testing every integer by repeated division scans far beyond the last ugly number.

The pointer build visits each rank once and keeps only three candidate products.

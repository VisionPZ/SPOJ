# COUNT — Counting Partition Schemes (SPOJ)

<https://www.spoj.com/problems/COUNT/>

## Problem

Count the ways to split N identical computers into K nonempty trucks when truck order does not matter. Report that count modulo 1988 for every query.

Input: each line holds two integers N and K with 1 ≤ K ≤ N ≤ 5000. A line holding 0 0 terminates the file and produces no output. Output: print one integer per query, on its own line.

| item | bound |
|---|---|
| computers N | 1 to 5000 |
| trucks K | 1 to N |
| modulus | 1988 |
| judge limit | 10000 ms, 1536 MB |

The modulus keeps every table entry inside a 16-bit cell.

The sample holds two queries before the terminating pair.

| sample input | sample output |
|---|---|
| 1 1 / 7 3 / 0 0 | 1 / 4 |

Seven computers fill three trucks in four distinct unordered ways.

## Idea

Add one truck at a time, like stacking one more step onto a staircase, and reuse every smaller count. The algorithm is dynamic programming over computers and trucks. Each state costs one addition from two earlier states, so the whole table costs O(NK). Enumerating each partition separately grows exponentially and stalls at N = 5000. Precompute once, then answer every query with one table lookup.

## Why It Works

1. A partition of N into K parts either contains a part of size one or does not.
2. Removing that part leaves a partition of N − 1 into K − 1 parts.
3. If no part equals one, subtracting one from every part leaves a partition of N − K into K parts.
4. The two cases are disjoint and cover every partition, so their counts add.
5. Reducing each count modulo 1988 preserves the final modulo answer.

| term | meaning |
|---|---|
| `partitionTable` | count for a given computer total and truck count |
| `trucksUsed` | current number of trucks in the DP sweep |
| `totalComputers` | current computer total in the sweep |
| `withoutOne` | count after subtracting one from every truck |
| `withOne` | count after removing a truck holding one computer |

The two named counts are the only ingredients of each state.

A scripted trace for seven computers fixes the answer at four.

| trucks K | script count for N = 7 |
|---|---|
| 1 | 1 |
| 2 | 3 |
| 3 | 4 |

The script enumerates first parts in decreasing order and adds nested counts.

All arithmetic stays in integers, so rounding never enters the computation.

## Code

**Input and scanning.** The reader loads all query pairs and records the largest bounds.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue = 1988

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
```

The scanner skips line breaks and spaces between the two integers.
The terminating pair stops the query loop before any table work.
The buffer flushes after a large block of answer lines.

**Table fill and answers.** One sweep fills every state, then lookups emit answers.

```nim
var computerCounts = newSeq[int]()
var truckCounts = newSeq[int]()
var largestComputers = 0
var largestTrucks = 0
while true:
  let computers = nextInt(inputData, scanPos)
  let trucks = nextInt(inputData, scanPos)
  if computers == 0 and trucks == 0:
    break
  computerCounts.add computers
  truckCounts.add trucks
  if computers > largestComputers:
    largestComputers = computers
  if trucks > largestTrucks:
    largestTrucks = trucks

let columnCount = largestTrucks + 1
var partitionTable = newSeq[uint16]((largestComputers + 1) * columnCount)
partitionTable[0] = uint16(1)
for trucksUsed in 1 .. largestTrucks:
  var totalComputers = trucksUsed
  while totalComputers <= largestComputers:
    let withoutOne = int(partitionTable[(totalComputers - trucksUsed) * columnCount + trucksUsed])
    let withOne = int(partitionTable[(totalComputers - 1) * columnCount + (trucksUsed - 1)])
    partitionTable[totalComputers * columnCount + trucksUsed] = uint16((withoutOne + withOne) mod modulusValue)
    totalComputers += 1

for queryIndex in 0 .. computerCounts.len - 1:
  let computers = computerCounts[queryIndex]
  let trucks = truckCounts[queryIndex]
  appendOutput($(partitionTable[computers * columnCount + trucks]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The outer loop fixes the truck count and the inner loop raises the computer total.
A 16-bit cell holds each residue and the final flush writes the buffered lines.

## Complexity

One table fill serves all queries after the input scan.

| phase | time | space |
|---|---|---|
| input read | one pass over query pairs | two query arrays |
| table fill | one sweep over all states | one 16-bit table |
| answers | one lookup per query | output buffer |

The table fill dominates the runtime and the table dominates memory.

| measure | Big O |
|---|---|
| time | O(NK + Q) |
| space | O(NK) |

Naive partition enumeration grows exponentially with N, while the table grows polynomially. Precomputing once keeps every later query nearly free.

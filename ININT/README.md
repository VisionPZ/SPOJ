# ININT — Incrementing The Integer (SPOJ)

<https://www.spoj.com/problems/ININT/>

## Problem

Starting from one, add any one digit of the current number to itself. For each query number, report the fewest steps to reach it and how many shortest paths exist, modulo 1000000007.

Every line of input holds one query integer, and input ends at end of file. Print `steps solutions` per line, or `IMPOSSIBLE` when no path reaches the number.

| item | bound |
|---|---|
| query value K | 1 to 1000000000 |
| number of queries | up to 100 |
| answer modulo | 1000000007 |
| judge limit | 1000 ms, 1536 MB |

The digit choices, not the digits' positions, define distinct paths.

Sample input:

```
16
100
87
```

Sample output:

```
4 1
17 2
IMPOSSIBLE
```

## Idea

Think of each number as a room with doors labelled by its digit values. Breadth-first search walks through these doors layer by layer, so the first arrival at a number is a shortest path.

Each room stores its step count and the number of ways to reach it. When another shortest path arrives, the way counts add. Repeated equal digits open one door, not several.

Skipping layers and guessing a path would miss the exact shortest count.

One breadth-first pass answers every query together.

## Why It Works

1. Starting from 1, every move adds one nonzero digit of the current number.
2. Breadth-first search reaches each number first in the fewest steps.
3. Equal digit values give one move, even when a digit appears twice.
4. Another path of the same length contributes its way count to that number.
5. A number with no assigned step count is unreachable and prints `IMPOSSIBLE`.

| term | meaning |
|---|---|
| `stepCount` | fewest steps to reach a number |
| `pathWays` | shortest-path count modulo the prime |
| `usedDigits` | bit mask removing duplicate digit choices |
| `largestQuery` | maximum query, which bounds the search |

A worked trace follows for the sample target 100.

```
1 to 2 to 4 to 8 to 16 takes 4 steps
16 to 17 to 24 to 28 to 36 to 39 to 48 to 56
56 to 62 to 68 to 76 to 83 to 91 to 100
two shortest paths reach 100
```

The trace matches the sample answer `17 2`.

## Code

**Input and buffered output.** All queries are read before the search begins.

```nim
const flushBlockBytes = 1 shl 17
const solutionModulus = int64(1000000007)

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

Queries arrive one per line until end of file.
The scanner skips the newline after each query.
Output lines accumulate in one buffer.

**Query collection.** The largest query fixes the search bound.

```nim
var queries = newSeq[int](0)
while true:
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  if scanPos >= inputData.len:
    break
  queries.add nextInt(inputData, scanPos)

var largestQuery = 1
for queryValue in queries:
  if queryValue > largestQuery:
    largestQuery = queryValue
```

Every query is stored in encounter order.
The stop check ignores trailing whitespace.
The largest value bounds both arrays.

**Breadth-first search.** Distinct digits drive each relaxation.

```nim
var stepCount = newSeq[int](largestQuery + 1)
var pathWays = newSeq[int64](largestQuery + 1)
for index in 0 .. largestQuery:
  stepCount[index] = -1
stepCount[1] = 0
pathWays[1] = 1

var queue = newSeq[int](largestQuery + 1)
var queueHead = 0
var queueTail = 0
queue[queueTail] = 1
queueTail += 1
while queueHead < queueTail:
  let currentNumber = queue[queueHead]
  queueHead += 1
  let nextStep = stepCount[currentNumber] + 1
  var remainder = currentNumber
  var usedDigits = 0
  while remainder > 0:
    let digitValue = remainder mod 10
    remainder = remainder div 10
    if digitValue == 0:
      continue
    let digitBit = 1 shl digitValue
    if (usedDigits and digitBit) != 0:
      continue
    usedDigits = usedDigits or digitBit
    let nextNumber = currentNumber + digitValue
    if nextNumber > largestQuery:
      continue
    if stepCount[nextNumber] < 0:
      stepCount[nextNumber] = nextStep
      pathWays[nextNumber] = pathWays[currentNumber]
      queue[queueTail] = nextNumber
      queueTail += 1
    elif stepCount[nextNumber] == nextStep:
      pathWays[nextNumber] = (pathWays[nextNumber] + pathWays[currentNumber]) mod solutionModulus
```

A bit mask removes repeated digit values.
A first visit fixes the steps and copies the ways.
A tied visit adds the ways modulo the prime.

**Answer loop.** Each query reads one pair of table entries.

```nim
for queryValue in queries:
  if stepCount[queryValue] < 0:
    appendOutput("IMPOSSIBLE")
  else:
    appendOutput($stepCount[queryValue] & " " & $pathWays[queryValue])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Unvisited numbers print the impossible message.
Visited numbers print steps and ways together.
The final flush writes all remaining lines.

## Complexity

The breadth-first pass dominates the runtime.

| phase | time | space |
|---|---|---|
| input read | one pass over query tokens | input string |
| shortest paths | O(K log 10) relaxations | step and way arrays |
| output | one buffered write per block | block buffer |

Each number enters the queue once and yields up to nine moves.

| measure | Big O |
|---|---|
| time | O(K) for the largest query K |
| space | O(K) |

Trying to guess a path without the search cannot give exact step counts.

The search visits each number once, so all queries share one table.

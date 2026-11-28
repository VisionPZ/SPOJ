# RIOI_3_2 — Counting (SPOJ)

<https://www.spoj.com/problems/RIOI_3_2/>

## Problem

Count the ways to choose N distinct positive integers whose sum stays at most M. Report each count modulo 1000000007.

Input starts with T, then T lines with N and M. Output one count per line in input order.

| item | bound |
|---|---|
| chosen count N | 1 to 20 |
| sum limit M | 0 to 100000 |
| test count T | not stated in the statement |
| judge limit | 100 ms, 1536 MB |

The product N times M sets the work per run.

Sample input:

```
4
6 16
4 16
1 14
3 7
```

Sample output:

```
0
27
14
2
```

## Idea

Slide every chosen number left by its rank, like pushing books together on a shelf. Distinct positive values become a nondecreasing list, and the problem turns into counting small partitions.

The algorithm shifts by 1..N, leaving spare sum M - N(N+1)/2. An unbounded knapsack over part sizes 1..N counts partitions, and a prefix array sums them. Each query costs O(1) after a shared O(N*M) build. Direct enumeration grows exponentially in N.

Takeaway: turn distinctness into a partition count, then use one knapsack table.

## Why It Works

1. Writing x(i) = i + y(i) forces y(1) <= y(2) <= ... <= y(N), all nonnegative.
2. The shift removes N(N+1)/2 from the budget, leaving spare = M - N(N+1)/2.
3. A negative spare means no set fits, so the answer is 0.
4. Unbounded parts of size 1..N generate every nondecreasing list once.
5. Summing partition counts up to spare gives all lists whose total fits the budget.

| term | meaning |
|---|---|
| `spareSum` | M minus the smallest possible sum for that N |
| `partitionCounts` | number of partitions of each total using parts up to the current size |
| `cumulativeCounts` | running sum of partition counts up to each total |
| `queryOrder` | query indices sorted by N so one table serves a whole group |

Each group reuses the table built for smaller part sizes.

A script-generated trace for N = 3 and M = 7:

```
N=3  M=7  spare=7-6=1
partition []   sum 0  -> chosen {1,2,3}
partition [1]  sum 1  -> chosen {1,2,4}
answer 2
```

The trace matches the last sample line.

## Code

**Input and scanning.** The hand reader loads all queries and the two maxima.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const modulus: int64 = 1000000007

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

let testCount = nextInt(inputData, scanPos)
var querySizes = newSeq[int](testCount)
var queryLimits = newSeq[int](testCount)
var largestSize = 0
var largestLimit = 0
for testIndex in 0 .. testCount - 1:
  querySizes[testIndex] = nextInt(inputData, scanPos)
  queryLimits[testIndex] = nextInt(inputData, scanPos)
  if querySizes[testIndex] > largestSize:
    largestSize = querySizes[testIndex]
  if queryLimits[testIndex] > largestLimit:
    largestLimit = queryLimits[testIndex]
```

Both maxima are known before any table is built.
Answers are stored in input order.
The scan ignores all line breaks.

**Query grouping.** Sorting by N lets one table answer a whole group.

```nim
var queryOrder = newSeq[int](testCount)
for testIndex in 0 .. testCount - 1:
  queryOrder[testIndex] = testIndex
queryOrder.sort(proc(leftIndex, rightIndex: int): int =
  if querySizes[leftIndex] < querySizes[rightIndex]:
    return -1
  if querySizes[leftIndex] > querySizes[rightIndex]:
    return 1
  return 0)
```

The comparator uses the stored query size.
An explicit comparator keeps old Nim compilers happy.
The original positions stay attached to every query.

**Shared partition table.** One in-place knapsack serves all queries with the same N.

```nim
var partitionCounts = newSeq[int64](largestLimit + 1)
partitionCounts[0] = 1
var cumulativeCounts = newSeq[int64](largestLimit + 1)
var answers = newSeq[int](testCount)
var orderPosition = 0

for partCount in 1 .. largestSize:
  for sumValue in partCount .. largestLimit:
    partitionCounts[sumValue] = (partitionCounts[sumValue] + partitionCounts[sumValue - partCount]) mod modulus
  cumulativeCounts[0] = partitionCounts[0]
  for sumValue in 1 .. largestLimit:
    cumulativeCounts[sumValue] = (cumulativeCounts[sumValue - 1] + partitionCounts[sumValue]) mod modulus
  while orderPosition < testCount and querySizes[queryOrder[orderPosition]] == partCount:
    let queryIndex = queryOrder[orderPosition]
    let spareSum = queryLimits[queryIndex] - partCount * (partCount + 1) div 2
    if spareSum < 0:
      answers[queryIndex] = 0
    else:
      answers[queryIndex] = int(cumulativeCounts[spareSum])
    orderPosition += 1
```

Ascending sums make the part reusable.
The modulus keeps every entry small.
A negative spare is answered as zero.

**Buffered output.** All answers are written in the original query order.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for testIndex in 0 .. testCount - 1:
  appendOutput($(answers[testIndex]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

One line follows each query.
Buffered writes avoid a system call per count.
The final flush closes the output.

## Complexity

The knapsack table is built once for the largest values present.

| phase | time | space |
|---|---|---|
| input read | one pass over query tokens | two query arrays |
| query sort | O(T log T) | sorted index array |
| knapsack build | O(N*M) | two sum arrays |
| output | one line per query | block buffer |

Sorting is small next to the knapsack table.

| measure | Big O |
|---|---|
| time | O(N*M + T log T) |
| space | O(M + T) |

Enumerating every set costs exponential time in N and cannot handle N = 20.

Takeaway: share one partition table across all queries of the same size.

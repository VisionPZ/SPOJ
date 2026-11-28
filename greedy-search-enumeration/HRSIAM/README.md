# HRSIAM — Angry Siam (SPOJ)

<https://www.spoj.com/problems/HRSIAM/>

## Problem

For each range query on the difficulty array, sum each position's difficulty times the angry value indexed by how many times that difficulty already appeared in the range. A second query type assigns a new difficulty to one position. Think of a guest who gets angrier each time the same dish is served again.

| item | bound |
|---|---|
| array size N | 1 to 100000 |
| operations Q | 1 to 100000 |
| values and angry entries | 1 to 100000 |
| judge limit | 2000 ms, 1536 MB |

The input gives N, the difficulty array, the angry array, Q, then one `t x y` line per operation. Type 1 asks for the range `[x, y]`; type 2 sets position `x` to `y`.

Sample input:

```
8
1 2 3 3 1 1 2 3
1 2 3 4 5 6 7 8
2
1 3 6
1 1 5
```

Sample output:

```
12
14
```

## Idea

Rewrite each answer as a sum over distinct difficulties: a difficulty seen `c` times contributes `d` times the prefix sum of the first `c` angry values. Then use Mo's algorithm with modifications, like moving a sliding window over both positions and time while keeping a running total. Adding or removing one position changes the total by one multiplication. Checking the whole range for every query costs far more. The takeaway is that one running count per difficulty makes each pointer move constant work.

## Why It Works

1. Every occurrence of difficulty `d` uses the angry value for its rank among equal difficulties.
2. All occurrences of the same `d` contribute `d` times the first `c` angry values, where `c` is the count.
3. Increasing a count from `c` to `c + 1` adds exactly `d × angry[c + 1]`.
4. Decreasing a count from `c` to `c - 1` removes exactly `d × angry[c]`.
5. Mo's ordering bounds the total movement of the left, right, and time pointers.
6. Each modification stores its old and new value, so time can move backward safely.

| term | meaning |
|---|---|
| `queryRecords` | sorted range queries with a time index |
| `occurrenceCounts` | current count for each difficulty |
| `activeSum` | running answer for the current window |
| `modificationOldValues` | value overwritten at each update time |
| `blockWidth` | Mo block size for the left endpoint |

The worked example uses the sample array and angry values from the statement.

| query | difficulties in range | count by difficulty | contribution | answer |
|---|---|---|---|---|
| 3 to 6 | 3, 3, 1, 1 | 3 appears twice, 1 appears twice | 3×1 + 3×2 + 1×1 + 1×2 | 12 |
| 1 to 5 | 1, 2, 3, 3, 1 | 1 twice, 2 once, 3 twice | 1×1 + 2×1 + 3×1 + 3×2 + 1×2 | 14 |

The running total uses 64-bit integers because a count can reach 100000.

## Code

**Parsing.** The reader turns type 1 lines into queries and type 2 lines into reversible modifications.

```nim
import algorithm

const flushBlockBytes = 1 shl 17

type QueryRecord = object
  leftEnd: int
  rightEnd: int
  timeIndex: int
  answerIndex: int
  leftBlock: int
  rightBlock: int

proc compareQueryRecords(leftQuery, rightQuery: QueryRecord): int =
  if leftQuery.leftBlock != rightQuery.leftBlock:
    if leftQuery.leftBlock < rightQuery.leftBlock:
      return -1
    return 1
  if leftQuery.rightBlock != rightQuery.rightBlock:
    if (leftQuery.leftBlock and 1) == 0:
      if leftQuery.rightBlock < rightQuery.rightBlock:
        return -1
      return 1
    if leftQuery.rightBlock > rightQuery.rightBlock:
      return -1
    return 1
  if leftQuery.timeIndex != rightQuery.timeIndex:
    if (leftQuery.leftBlock and 1) == 0:
      if leftQuery.timeIndex < rightQuery.timeIndex:
        return -1
      return 1
    if leftQuery.timeIndex > rightQuery.timeIndex:
      return -1
    return 1
  return 0
```

The comparator alternates direction between left blocks.
Alternation reduces total pointer travel between queries.

```nim
let problemCount = nextInt(inputData, scanPos)
var currentValues = newSeq[int](problemCount + 1)
var initialValues = newSeq[int](problemCount + 1)
var maxDifficulty = 0
for position in 1 .. problemCount:
  currentValues[position] = nextInt(inputData, scanPos)
  initialValues[position] = currentValues[position]
  if currentValues[position] > maxDifficulty:
    maxDifficulty = currentValues[position]
var angerValues = newSeq[int](problemCount + 1)
for position in 1 .. problemCount:
  angerValues[position] = nextInt(inputData, scanPos)
let operationCount = nextInt(inputData, scanPos)

var queryRecords = newSeq[QueryRecord]()
var modificationPositions = newSeq[int]()
var modificationOldValues = newSeq[int]()
var modificationNewValues = newSeq[int]()
modificationPositions.add 0
modificationOldValues.add 0
modificationNewValues.add 0
var updateCount = 0
for operationIndex in 0 .. operationCount - 1:
  let operationType = nextInt(inputData, scanPos)
  let firstValue = nextInt(inputData, scanPos)
  let secondValue = nextInt(inputData, scanPos)
  if operationType == 1:
    queryRecords.add QueryRecord(leftEnd: firstValue, rightEnd: secondValue, timeIndex: updateCount,
                                 answerIndex: queryRecords.len, leftBlock: 0, rightBlock: 0)
  else:
    updateCount += 1
    modificationPositions.add firstValue
    modificationOldValues.add currentValues[firstValue]
    modificationNewValues.add secondValue
    currentValues[firstValue] = secondValue
    if secondValue > maxDifficulty:
      maxDifficulty = secondValue
```

The initial array is saved before any modification.
Each update records both the overwritten and the new value.
Queries remember how many updates preceded them.

**Window updates.** Four helpers keep the running sum and counts consistent.

```nim
var occurrenceCounts = newSeq[int](maxDifficulty + 1)
var activeSum: int64 = 0
var activeLeft = 1
var activeRight = 0
var activeTime = 0

proc addPosition(position: int) =
  let difficulty = workValues[position]
  occurrenceCounts[difficulty] += 1
  activeSum = activeSum + int64(difficulty) * int64(angerValues[occurrenceCounts[difficulty]])

proc removePosition(position: int) =
  let difficulty = workValues[position]
  occurrenceCounts[difficulty] -= 1
  activeSum = activeSum - int64(difficulty) * int64(angerValues[occurrenceCounts[difficulty] + 1])
```

Adding a position uses the new count directly.
Removing a position subtracts the angry value it used.

```nim
proc applyModification(timeIndex: int) =
  let position = modificationPositions[timeIndex]
  let replacement = modificationNewValues[timeIndex]
  if position >= activeLeft and position <= activeRight:
    removePosition(position)
    workValues[position] = replacement
    addPosition(position)
  else:
    workValues[position] = replacement

proc revertModification(timeIndex: int) =
  let position = modificationPositions[timeIndex]
  let previous = modificationOldValues[timeIndex]
  if position >= activeLeft and position <= activeRight:
    removePosition(position)
    workValues[position] = previous
    addPosition(position)
  else:
    workValues[position] = previous
```

A change inside the window updates the total immediately.
A change outside the window only edits the working array.

**Sweep.** Sorted queries drive the three pointers, and answers are written in input order.

```nim
var answerValues = newSeq[int64](queryRecords.len)
for queryRecord in queryRecords:
  while activeTime < queryRecord.timeIndex:
    activeTime += 1
    applyModification(activeTime)
  while activeTime > queryRecord.timeIndex:
    revertModification(activeTime)
    activeTime -= 1
  while activeLeft > queryRecord.leftEnd:
    activeLeft -= 1
    addPosition(activeLeft)
  while activeRight < queryRecord.rightEnd:
    activeRight += 1
    addPosition(activeRight)
  while activeLeft < queryRecord.leftEnd:
    removePosition(activeLeft)
    activeLeft += 1
  while activeRight > queryRecord.rightEnd:
    removePosition(activeRight)
    activeRight -= 1
  answerValues[queryRecord.answerIndex] = activeSum
```

Time moves before the position window.
Every pointer move performs one constant-time update.
The answer index restores the original query order.

```nim
for answerValue in answerValues:
  appendOutput($answerValue)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

All answers collect in one output buffer.
A single write flushes the remaining text.

## Complexity

Mo's ordering bounds total pointer movement across all queries.

| phase | time | space |
|---|---|---|
| parsing | one pass over Q operations | query and update arrays |
| sort | O(Q log Q) | query array |
| sweep | O((N + Q) to the 5/3 power) | count array |

| measure | Big O |
|---|---|
| time | O((N + Q)^(5/3)) |
| space | O(N + Q + max difficulty) |

Rescanning the range for every query costs O(NQ) per query batch. The takeaway is that Mo's ordering turns repeated scans into bounded pointer moves.

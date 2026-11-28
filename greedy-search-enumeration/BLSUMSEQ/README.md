# BLSUMSEQ — Sum of subsequences (SPOJ)

<https://www.spoj.com/problems/BLSUMSEQ/>

## Problem

For each range of a sequence, answer either the k-th positive integer that no subsequence can sum to, or the number of non-empty subsequences that sum to a given value. Counts for the second query wrap modulo 2^32.

Input gives n and q, then n values, then q query lines. A query of kind 0 with fields l, r and k asks for the missing integer. A query of kind 1 with fields l, r and x asks for the subsequence count. Output one answer per query in input order.

| item | bound |
|---|---|
| values n | 1 to 100 |
| queries q | 1 to 10000 |
| each value | 0 to 100 |
| k and x | 0 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

The small value bound keeps every subset sum within 10000.

Sample input:

```
5 3
1 0 2 4 1
0 2 3 2
1 1 4 0
1 2 5 3
```

Sample output:

```
3
1
2
```

The range 2..3 holds 0 and 2, so 1 and 3 are the first two missing positives.

## Idea

Filling a piggy bank with one more coin doubles the ways to reach old totals and shifts copies to new totals, while the gaps between filled totals reveal missing sums. Use subset-sum dynamic programming that grows each range one value at a time. Each appended value costs O(S) updates, where S is the largest possible sum. Testing every subsequence for every query would cost O(q * 2^n). One growing range per left endpoint handles all queries at once.

## Why It Works

1. Every subsequence of a grown range either skips or uses the newest value.
2. Skipping keeps each old total; using adds the newest value to it.
3. The recurrence counts all subsequences, including the empty one.
4. A zero-sum query subtracts the empty subsequence to count non-empty ones.
5. A separate reachability flag survives the modulo wrap of the counts.
6. Beyond the largest reachable sum, every positive integer is missing, so large k skips straight there.

The main terms:

| term | meaning |
|---|---|
| `counts` | number of subsequences reaching each total, modulo 2^32 |
| `reachable` | whether at least one subsequence reaches each total |
| `currentSum` | largest total available in the current range |
| `addedValue` | value appended to the range at this step |
| `queriesByLeft` | queries grouped by their left endpoint |

Counts and reachability answer the two query types independently.

A script trace of the sample ranges:

```
segment 1..4: [1, 0, 2, 4]
subset sums: [0, 1, 2, 3, 4, 5, 6, 7]
missing positives: 8, 9, 10, ...
segment 2..3: [0, 2]
ways to sum 3: 2
```

Every positive total up to 7 is present in the full range, so the first gap is 8.

## Code

**Input, query grouping, and buffers.** Queries wait at their left endpoint until the range reaches them.

```nim
const flushBlockBytes = 1 shl 17
const countMask = 4294967295'i64

type Query = object
  kind: int
  leftIndex: int
  rightIndex: int
  parameter: int
  order: int

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

The mask keeps each count inside 32 unsigned bits.
The query object stores the original order for the answers.
The scanner reads all tokens through one buffer.

**Range setup.** Every left endpoint starts with only the empty subsequence.

```nim
let itemCount = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
var values = newSeq[int](itemCount)
var totalSum = 0
for itemIndex in 0 .. itemCount - 1:
  values[itemIndex] = nextInt(inputData, scanPos)
  totalSum += values[itemIndex]
var queriesByLeft = newSeq[seq[Query]](itemCount)
for queryIndex in 0 .. queryCount - 1:
  var query: Query
  query.kind = nextInt(inputData, scanPos)
  query.leftIndex = nextInt(inputData, scanPos) - 1
  query.rightIndex = nextInt(inputData, scanPos) - 1
  query.parameter = nextInt(inputData, scanPos)
  query.order = queryIndex
  queriesByLeft[query.leftIndex].add query
var answers = newSeq[int](queryCount)
var counts = newSeq[int64](totalSum + 1)
var reachable = newSeq[bool](totalSum + 1)
```

Two arrays of size totalSum plus one hold the tables.
Each query lands in the bucket of its left endpoint.
Answers keep their input positions for the final print.

**Growing ranges and answering.** Each appended value updates totals from high to low.

```nim
for leftIndex in 0 .. itemCount - 1:
  for sumIndex in 0 .. totalSum:
    counts[sumIndex] = 0'i64
    reachable[sumIndex] = false
  counts[0] = 1'i64
  reachable[0] = true
  var currentSum = 0
  for rightIndex in leftIndex .. itemCount - 1:
    let addedValue = values[rightIndex]
    var sumIndex = currentSum
    while sumIndex >= 0:
      let previousCount = counts[sumIndex]
      if previousCount != 0'i64:
        counts[sumIndex + addedValue] = (counts[sumIndex + addedValue] + previousCount) and countMask
      if reachable[sumIndex]:
        reachable[sumIndex + addedValue] = true
      sumIndex -= 1
    currentSum += addedValue
    for query in queriesByLeft[leftIndex]:
      if query.rightIndex != rightIndex:
        continue
      if query.kind == 1:
        if query.parameter > currentSum:
          answers[query.order] = 0
        else:
          var result = counts[query.parameter]
          if query.parameter == 0:
            result = (result - 1'i64) and countMask
          answers[query.order] = int(result)
      else:
        var missing = 0
        var found = false
        for value in 1 .. currentSum:
          if not reachable[value]:
            missing += 1
            if missing == query.parameter:
              answers[query.order] = value
              found = true
              break
        if not found:
          answers[query.order] = currentSum + (query.parameter - missing)

for answer in answers:
  appendOutput($(answer))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Descending totals prevent one value from being used twice.
A missed k beyond currentSum jumps directly to the tail of missing integers.
The empty subsequence is removed only for a zero-sum count query.

## Complexity

Let S be the sum of all values, at most 10000.

| phase | time | space |
|---|---|---|
| input and grouping | one pass over queries | one query record each |
| range growth | O(n^2 * S) table updates | two tables of size S |
| queries | O(q * S) worst case | answer per query |
| output | one line per query | block buffer |

All queries share the same grown ranges.

| measure | Big O |
|---|---|
| time | O(n^2 * S + q * S) |
| space | O(S + q) |

Enumerating subsequences per query costs O(q * 2^n), far larger for n near 100.
Shared dynamic programming replaces that work with one table per range.

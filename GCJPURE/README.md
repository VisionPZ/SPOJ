# GCJPURE — Your Rank is Pure (SPOJ)

<https://www.spoj.com/problems/GCJPURE/>

## Problem

Choose a subset of numbers from 2 to n and check whether repeated rank-taking from n reaches 1. Count the subsets that succeed, modulo 100003.

The first input line holds `caseCount`. Each following line holds one value n. For each case, print Case #x: y, where x is the one-based case number and y is the count.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases T | up to 200 |
| Query n | 2 to 500 |
| Modulus | 100003 |
| Judge limit | 1000 ms, 1536 MB |

All queries fit a single precomputation up to the largest n, so 200 cases cost no extra work per case.

The sample input:

```
2
5
6
```

The sample output:

```
Case #1: 5
Case #2: 8
```

The five valid subsets for n = 5 confirm the sample output.

## Idea

Rank-taking drops from n to the size of the chosen set. Think of following a chain of labels until label 1 appears. Each valid set is counted by its chosen size.

The algorithm is dynamic programming over the value and the chosen set size. Let `pureWays` hold counts for a value and a set size, and let `binom` supply ordinary binomial coefficients. For a set of size s, the chain moves to s. The lower part must already be a pure set for s. Each transition costs one table lookup. A brute-force check over all subsets would take two to the power of n steps, impossible at n = 500. The takeaway is to count by set size instead of listing sets.

## Why It Works

1. The rank of the largest number n in a chosen set equals the size s of that set.
2. The next chain value is therefore s, and adding larger numbers below n cannot change ranks at or below s.
3. The elements of the set up to s form a pure set for s of some size k.
4. The remaining s - 1 - k elements are chosen freely from the numbers s + 1 to n - 1.
5. Binomial coefficients count those free choices, and the recurrence sums over k.
6. A set of size one is always valid, which gives the base term `pureWays[value * tableWidth + 1] = 1`.

The main terms:

| Term | Meaning |
|---|---|
| `binom` | binomial coefficients modulo 100003 |
| `pureWays` | counts by value and chosen set size |
| `answerByValue` | total valid subsets for each value |
| `largestQuery` | upper bound for both tables |

The table shows that each query becomes a constant-time lookup after precomputation.

The generator trace for n = 5 lists every valid subset by brute force:

```
(5)            rank 1, reaches 1
(2,5)          rank 2, then rank 1
(2,3,5)        rank 3, then rank 2, then rank 1
(2,3,4,5)      rank 4, then 3, then 2, then 1
(3,4,5)        rank 3, then rank 1
count = 5
```

The trace matches the first sample answer.

## Code

**Input and scanning.** The reader collects all queries and finds the largest value.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue = 100003

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

All lines enter one input string before parsing starts.
The scanner skips whitespace between the T queries.
Finding the largest query keeps the tables as small as needed.

**Output and table setup.** The buffered writer is prepared, and binomial coefficients are built by Pascal's rule.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
var queries = newSeq[int](caseCount)
var largestQuery = 2
for caseIndex in 0 .. caseCount - 1:
  queries[caseIndex] = nextInt(inputData, scanPos)
  if queries[caseIndex] > largestQuery:
    largestQuery = queries[caseIndex]

let tableWidth = largestQuery + 2
let binomWidth = largestQuery + 1
var binom = newSeq[int](binomWidth * binomWidth)
for row in 0 .. largestQuery:
  binom[row * binomWidth] = 1
  binom[row * binomWidth + row] = 1
  for column in 1 .. row - 1:
    binom[row * binomWidth + column] = (binom[(row - 1) * binomWidth + column - 1] + binom[(row - 1) * binomWidth + column]) mod modulusValue
```

Flat arrays replace nested sequences for the judge compiler.
Pascal's rule builds each coefficient from two earlier entries.
All entries stay below 100003 after each addition.

**Counting and output.** The recurrence fills `pureWays`, then each case prints its cached answer.

```nim
var pureWays = newSeq[int]((largestQuery + 1) * tableWidth)
pureWays[tableWidth] = 1
var answerByValue = newSeq[int](largestQuery + 1)
answerByValue[1] = 1
for value in 2 .. largestQuery:
  pureWays[value * tableWidth + 1] = 1
  for setSize in 2 .. value:
    let upper = value - 1 - setSize
    if upper < 0:
      continue
    var total: int64 = 0
    for subsetSize in 1 .. setSize:
      let needed = setSize - 1 - subsetSize
      if needed >= 0 and needed <= upper:
        total = total + int64(pureWays[setSize * tableWidth + subsetSize]) * int64(binom[upper * binomWidth + needed])
    pureWays[value * tableWidth + setSize] = int(total mod int64(modulusValue))
  var answer: int64 = 0
  for setSize in 1 .. value:
    answer = answer + int64(pureWays[value * tableWidth + setSize])
  answerByValue[value] = int(answer mod int64(modulusValue))

for caseIndex in 0 .. caseCount - 1:
  let query = queries[caseIndex]
  appendOutput("Case #" & $(caseIndex + 1) & ": " & $answerByValue[query] & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Products use int64 before the modulus is applied.
Guards skip binomial terms with invalid indexes.
The buffer flushes once after all cases are formatted.

## Complexity

Precomputation grows cubically with the largest query, and every answer is then a table read.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over T queries | query array |
| Binomial table | O(n squared) | n squared integers |
| Pure-set table | O(n cubed) | n squared integers |
| Output | one line per case | block buffer |

The table shows that the pure-set table dominates both time and space.

| Measure | Big O |
|---|---|
| Time | O(n cubed + T) |
| Space | O(n squared) |

Enumerating all subsets would need two to the power of n steps and cannot handle n = 500. Counting by set size reduces the work to a fixed table and answers every query in constant time.

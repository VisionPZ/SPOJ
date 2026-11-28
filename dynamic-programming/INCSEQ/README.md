# INCSEQ — Increasing Subsequences (SPOJ)

<https://www.spoj.com/problems/INCSEQ/>

## Problem

Count index tuples that pick K increasing positions and strictly increasing values. Print that count modulo 5,000,000. One test is given.

Line 1 holds N and K. The next N lines hold the sequence values in order. Output holds one integer.

| item | bound |
|---|---|
| length N | 1 to 10,000 |
| subsequence length K | 1 to 50, and at most N |
| value Si | 0 to 99,999 |
| modulus | 5,000,000 |
| judge limit | 1000 ms, 1536 MB |

Repeated values count as distinct choices of positions here.

Sample input and output:

```
4 3
1
2
2
10
```

```
2
```

The two tuples are (1, 2, 4) and (1, 3, 4).

## Idea

Each new value extends shorter subsequences, like stacking blocks where every new block must be taller than the top one. A Fenwick tree stores counts grouped by last value, so the sum of all smaller tops is one prefix query.

Process lengths from K down to 2 before adding the new single-element subsequence. Descending order stops one element from being used twice. Each element costs K prefix queries and K updates, each O(log V). A direct scan over earlier positions costs O(N) per length and is too slow at full size.

Fenwick trees turn the value scan into a short prefix sum.

## Why It Works

1. Let dp[k][x] be the number of increasing subsequences of length k whose last value is x among processed elements.
2. A new value x extends exactly the subsequences of length k-1 with last value below x.
3. The Fenwick tree for length k-1 answers that smaller-value sum in O(log V).
4. Updating lengths from K down to 2 keeps the current element out of its own extension counts.
5. The length-1 tree gains one for every occurrence, so equal values are counted as separate position choices.
6. The final answer is the total over all last values in the length-K tree.

| term | meaning |
|---|---|
| `fenwickTrees` | one Fenwick tree per subsequence length |
| `valueLimit` | 100,000, the size of the value domain |
| `prefixQuery` | sum of counts for values strictly below the new value |
| `addToTree` | add a count at one value and all covering tree nodes |
| `subsequenceLength` | K, the target length |

The table connects the recurrence to the code.

A scripted trace of the sample uses K = 3 and values 1, 2, 2, 10.

```
value 1: length 1 total = 1
value 2: length 2 total += smaller length-1 count 1 -> 1
value 2 again: length 2 total += smaller length-1 count 1 -> 2
value 10: length 3 total += smaller length-2 count 2 -> 2
answer = 2
```

The second 2 adds a new tuple but not a new distinct value pair, matching the sample.

## Code

**Input and Fenwick setup.** The reader loads values and builds one tree per length.

```nim
const flushBlockBytes = 1 shl 17
const valueLimit = 100000
const modulusValue = 5000000

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

The value domain is fixed at 100,000.
Tree indexes are one-based, so a value maps to index value + 1.
All counts stay below the modulus.

**Tree operations.** Prefix sums collect smaller values and point updates extend one value.

```nim
proc prefixQuery(tree: seq[int], upperIndex: int): int =
  var total = 0
  var cursor = upperIndex
  while cursor > 0:
    total = (total + tree[cursor]) mod modulusValue
    cursor -= cursor and (-cursor)
  return total

proc addToTree(tree: var seq[int], startIndex: int, deltaValue: int) =
  var cursor = startIndex
  while cursor <= valueLimit:
    tree[cursor] = (tree[cursor] + deltaValue) mod modulusValue
    cursor += cursor and (-cursor)
```

The query stops at index value, which excludes equal values.
The update walks the usual Fenwick parent chain.
Both operations take at most 17 steps.

**Descending length sweep.** Each element extends longer subsequences before becoming a length-one start.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let elementCount = nextInt(inputData, scanPos)
let subsequenceLength = nextInt(inputData, scanPos)
var fenwickTrees = newSeq[seq[int]](subsequenceLength + 1)
for lengthIndex in 0 .. subsequenceLength:
  fenwickTrees[lengthIndex] = newSeq[int](valueLimit + 1)
for position in 0 .. elementCount - 1:
  let currentValue = nextInt(inputData, scanPos)
  let treeIndex = currentValue + 1
  for lengthIndex in countdown(subsequenceLength, 2):
    let smallerTotal = prefixQuery(fenwickTrees[lengthIndex - 1], currentValue)
    addToTree(fenwickTrees[lengthIndex], treeIndex, smallerTotal)
  addToTree(fenwickTrees[1], treeIndex, 1)
let answerValue = prefixQuery(fenwickTrees[subsequenceLength], valueLimit)
appendOutput($answerValue)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Descending lengths prevent reuse of the current element.
The single line of output is written through the block buffer.
The result is already reduced modulo 5,000,000.

## Complexity

The cost is one pair of Fenwick operations per length and element.

| phase | time | space |
|---|---|---|
| input read | one pass over N values | one input string |
| length sweep | N times K tree operations | K trees over the value domain |
| output | one line | block buffer |

The tree work dominates the runtime.

| measure | Big O |
|---|---|
| time | O(N K log V) |
| space | O(K V) |

Naive extension by scanning earlier positions costs O(N^2 K) and is far slower.

Fenwick trees reduce each extension to a short prefix walk.

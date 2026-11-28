# BRICKS — New Bricks Disorder (SPOJ)
<https://www.spoj.com/problems/BRICKS/>

## Problem

Each case gives a start word, a target word, and pairs of letters whose bricks may swap when adjacent. Find the minimum number of swaps, or -1 if the target is unreachable.

Input starts with a case count. Each case holds two lowercase words, then a pair count m, then m letter pairs. Output the minimum swap count modulo 2^32, or -1.

The limits set the size of the counting structures.

| Quantity | Limit |
| --- | --- |
| Row length | up to 100,000 letters |
| Alphabet | 26 lowercase letters |
| Time limit | 9000 ms |
| Memory limit | 1536 MB |

The tree holds one slot per brick, and the alphabet fixes 26 letter trees.

The sample input and output:

```
4
ab
ba
0
abc
cba
3
a b
c b
c a
cabbbc
cbabbc
1
a b
abba
baab
1
a b
```

```
-1
3
1
2
```

The first case has no allowed pair, so it prints -1.

## Idea

Fix each brick's identity by its occurrence order. The k-th `a` in the start word must become the k-th `a` in the target word. An adjacent swap reverses exactly one pair of bricks, and that reversal is legal only when the two letters form an allowed pair. Count all needed reversals with Fenwick trees (prefix counters over target indices).

Each brick triggers at most 26 prefix queries, and each query touches about 17 tree slots, so the cost is O(26 L log L). Simulating swaps would branch without bound and cannot yield a minimum.

Takeaway: count legal inversions, do not simulate swaps.

## Why It Works

1. Identical bricks are interchangeable, so pairing occurrences in order is forced and optimal.
2. That pairing produces the `targetIndexAt` array, one target position per start brick.
3. An adjacent swap reverses exactly one pair of bricks, so each legal swap removes one inversion.
4. A reversal is allowed only when the two letters appear in `adjacencyMask`.
5. A Fenwick tree returns a prefix sum in logarithmic time, so inversions are counted in one sweep.

The tables split the work by letter.

| Term | Meaning |
| --- | --- |
| `adjacencyMask` | one bit per allowed partner letter |
| `positionLists` | target positions of each letter, in order |
| `targetIndexAt` | target index assigned to each start brick |
| `totalTree` | Fenwick tree over all bricks |
| `letterTrees[l]` | Fenwick tree over bricks of one letter |

All inversions minus connected inversions must vanish, or the answer is -1.

A script traced the second sample case, `abc` to `cba`:

| Start brick | Target index | Inversions with earlier bricks |
| --- | --- | --- |
| a | 2 | 0 |
| b | 1 | 1, with a |
| c | 0 | 2, with a and b |

All three pairs are allowed, so the answer is 3.

## Code

**Input and scanners.**
```nim
const
  flushBlockBytes = 1 shl 18
  letterKinds = 26
  firstLetterCode = 97
  firstDigitCode = 48
  moduloBase = 4294967296'i64

var inputData = ""
var lineBuffer = ""
while readLine(stdin, lineBuffer):
  inputData.add(lineBuffer)
  inputData.add('\n')

var i = 0

proc skipWhitespace(data: string, i: var int) =
  while i < data.len and data[i] <= ' ':
    inc i

proc nextInt(data: string, i: var int): int =
  skipWhitespace(data, i)
  result = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    result = result * 10 + (int(data[i]) - firstDigitCode)
    inc i

proc readWord(data: string, i: var int): tuple[start: int, length: int] =
  skipWhitespace(data, i)
  result.start = i
  while i < data.len and data[i] >= 'a' and data[i] <= 'z':
    inc i
  result.length = i - result.start
```
The buffer gathers the whole stream. `readWord` returns a start and length slice, and `nextInt` skips whitespace. `moduloBase` is 2^32, the required output modulus.

**Fenwick helpers and output.**
```nim
proc bitAdd(tree: var seq[int], i: int) =
  var j = i
  while j < tree.len:
    tree[j] += 1
    j += j and (-j)

proc bitSum(tree: var seq[int], i: int): int =
  var j = i
  result = 0
  while j > 0:
    result += tree[j]
    j -= j and (-j)

var outputBuffer = ""

proc flushOutput() =
  stdout.write(outputBuffer)
  outputBuffer.setLen(0)

proc appendAnswer(answer: int64) =
  outputBuffer.add($answer)
  outputBuffer.add('\n')
  if outputBuffer.len >= flushBlockBytes:
    flushOutput()
```
`bitAdd` walks upward adding one, and `bitSum` walks downward collecting a prefix. `appendAnswer` prints each answer and flushes at the block boundary.

**Case parsing and brick matching.**
```nim
let caseCount = nextInt(inputData, i)
for j in 0 .. caseCount - 1:
  let sourceWord = readWord(inputData, i)
  let targetWord = readWord(inputData, i)
  let pairCount = nextInt(inputData, i)

  var adjacencyMask: array[letterKinds, int]
  for k in 0 .. pairCount - 1:
    skipWhitespace(inputData, i)
    let leftLetter = int(inputData[i]) - firstLetterCode
    inc i
    skipWhitespace(inputData, i)
    let rightLetter = int(inputData[i]) - firstLetterCode
    inc i
    adjacencyMask[leftLetter] = adjacencyMask[leftLetter] or (1 shl rightLetter)
    adjacencyMask[rightLetter] = adjacencyMask[rightLetter] or (1 shl leftLetter)

  var possible = true
  var sourceFreq: array[letterKinds, int]
  var targetFreq: array[letterKinds, int]
  for k in 0 .. sourceWord.length - 1:
    inc sourceFreq[int(inputData[sourceWord.start + k]) - firstLetterCode]
  for k in 0 .. targetWord.length - 1:
    inc targetFreq[int(inputData[targetWord.start + k]) - firstLetterCode]
  for k in 0 .. letterKinds - 1:
    if sourceFreq[k] != targetFreq[k]:
      possible = false

  var answer: int64 = 0
  if possible and sourceWord.length > 0:
    var positionLists: array[letterKinds, seq[int]]
    for k in 0 .. letterKinds - 1:
      positionLists[k] = newSeq[int](targetFreq[k])
    var filled: array[letterKinds, int]
    for k in 0 .. targetWord.length - 1:
      let l = int(inputData[targetWord.start + k]) - firstLetterCode
      positionLists[l][filled[l]] = k
      inc filled[l]

    var targetIndexAt = newSeq[int](sourceWord.length)
    for k in 0 .. letterKinds - 1:
      filled[k] = 0
    for k in 0 .. sourceWord.length - 1:
      let l = int(inputData[sourceWord.start + k]) - firstLetterCode
      targetIndexAt[k] = positionLists[l][filled[l]]
      inc filled[l]

```
The code reads both words and the allowed pairs. It builds `positionLists` from the target word, then fills `targetIndexAt` from the start word by occurrence order.

**Inversion counting.**
```nim
    var connectedNeighbours: array[letterKinds, seq[int]]
    for k in 0 .. letterKinds - 1:
      connectedNeighbours[k] = newSeq[int]()
      for l in 0 .. letterKinds - 1:
        if (adjacencyMask[k] and (1 shl l)) != 0:
          connectedNeighbours[k].add(l)

    var totalTree = newSeq[int](sourceWord.length + 1)
    var letterTrees: array[letterKinds, seq[int]]
    var letterTotals: array[letterKinds, int]
    for k in 0 .. letterKinds - 1:
      letterTrees[k] = newSeq[int](sourceWord.length + 1)

    for k in 0 .. sourceWord.length - 1:
      let l = int(inputData[sourceWord.start + k]) - firstLetterCode
      let i = targetIndexAt[k] + 1
      let allInversions = k - bitSum(totalTree, i)
      var connectedInversions = 0
      for j in connectedNeighbours[l]:
        connectedInversions += letterTotals[j] - bitSum(letterTrees[j], i)
      if connectedInversions != allInversions:
        possible = false
        break
      answer += int64(connectedInversions)
      bitAdd(totalTree, i)
      bitAdd(letterTrees[l], i)
      inc letterTotals[l]

  if not possible:
    outputBuffer.add("-1\n")
  else:
    appendAnswer(answer mod moduloBase)

flushOutput()
```
For each brick, `allInversions` counts earlier bricks with a larger target index. `connectedInversions` counts only allowed letter partners. A mismatch sets `possible` to false; otherwise the answer is accumulated modulo `moduloBase`.

## Complexity

The alphabet is a fixed 26, so the row length dominates.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | one pass over input bytes | input bytes |
| Brick matching | O(L) | 26 position lists |
| Fenwick queries | O(26 L log L) | 27 trees of size L |
| Output | one write per block | flushBlockBytes |

Each brick pays for one query per possible partner letter.

| Measure | Big O |
| --- | --- |
| Time per case | O(26 L log L) |
| Space per case | O(26 L) |

Searching swap sequences would be exponential, while inversion counting gives the exact minimum in one pass.

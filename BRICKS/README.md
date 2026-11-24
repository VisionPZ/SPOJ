## Problem

Each case gives a start row and a target row of bricks. One letter is written on each brick.
A list of letter pairs names the adjacent pairs we may swap.
Print the minimum swaps that build the target row, or `-1` when no sequence works.
Print the count modulo 2^32.

The limits set the size of the counting structures.

| Quantity | Limit |
| --- | --- |
| Row length | 100,000 letters |
| Alphabet | 26 lowercase letters |
| Time limit | 9,000 ms |
| Memory limit | 1,536 MB |

The tree holds one slot per brick, and the alphabet fixes 26 letter trees.

## Idea

Fix the identity of every brick by occurrence order.
The k-th `a` in the start row must become the k-th `a` in the target row.
This rule gives each brick one target index.
Adjacent swaps reverse the order of exactly the two bricks swapped.
So a reversal is legal only when the letter pair appears in the given list.
A Fenwick tree (a prefix counter over target indices) counts legal crossings in one pass.
We keep one tree for all bricks and one tree per letter.

Cost per brick: at most 25 prefix queries, each touching about 17 tree slots.

## Why It Works

Identical bricks are interchangeable.
Pairing occurrences in order is therefore forced and optimal.
That pairing produces the `targetIndexAt` array.

An adjacent swap reverses exactly one pair of bricks.
A reversal needs the two letters in `adjacencyMask`.
Each legal swap removes one reversal from `targetIndexAt`.
The number of legal reversals is the minimum swap count.

A Fenwick tree returns a prefix sum in logarithmic time.
We use these counts at each brick:

- `i = targetIndexAt[k] + 1` shifts a zero-based target index to a one-based slot.
- `allInversions = k - bitSum(totalTree, i)` counts earlier bricks with a larger target index.
- `connectedInversions += letterTotals[j] - bitSum(letterTrees[j], i)` keeps crossings with an allowed letter.
- `answer += int64(connectedInversions)` totals the legal crossings.

When `allInversions` exceeds `connectedInversions`, an illegal crossing exists.
The program then prints `-1`.

A small case shows the mapping and the sweep for `abba` to `baab` with the pair `a b`:

```
offset 0 letter a occurrence 0 target index 1
offset 1 letter b occurrence 0 target index 0
offset 2 letter b occurrence 1 target index 3
offset 3 letter a occurrence 1 target index 2
targetIndexAt = [1, 0, 3, 2]
offset 0 slot 2 all 0 connected 0 answer 0
offset 1 slot 1 all 1 connected 1 answer 1
offset 2 slot 4 all 0 connected 0 answer 1
offset 3 slot 3 all 1 connected 1 answer 2
final answer 2
```

The two crossings sit at offsets 1 and 3, and both use the allowed `a b` pair.

## Code

Each block below is copied from the program.

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

Five constants set the block size and the alphabet. The read loop builds one input buffer. The scanner walks that buffer by index. No token is copied.

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
```

`j and (-j)` selects the lowest set bit. Each loop runs once per bit. A 100,000 slot tree has about 17 levels.

```nim
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

`setLen(0)` reuses the same buffer. The write happens at 256 KiB, not per answer. The final flush writes any remainder.

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
```

The pair loop runs `pairCount` times. Each pair sets both bitmap directions. The frequency check rejects mismatched rows before any tree work.

```nim
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
```

These loops run once per brick or once per letter. `positionLists` stores target slots in occurrence order. Each tree starts empty with one slot per brick.

```nim
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

The sweep runs once per brick. The equality test stops at the first illegal crossing. Each update touches about 17 slots. The modulo keeps the printed count inside 32 bits.

## Complexity

Let `n` be the row length and `d` the largest neighbour count of one letter.
The value of `d` is at most 25.

The phases cost the following:

- Input read: O(total input bytes) in one pass.
- Occurrence mapping: O(n) time and O(n) space.
- Tree setup: O(26 x n) space for the per-letter trees.
- Sweep: O(n x d x log n) time.
- Output: O(cases) bytes, flushed in 256 KiB blocks.

The sweep dominates the run time.
Total time is O(n x d x log n) per case, and total space is O(26 x n).
A direct check of every brick pair would cost O(n^2) time.

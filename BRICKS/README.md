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

- `positionIndex = targetIndexAt[offset] + 1` shifts a zero-based target index to a one-based slot.
- `allInversions = offset - bitSum(totalTree, positionIndex)` counts earlier bricks with a larger target index.
- `connectedInversions += letterTotals[neighbourIndex] - bitSum(letterTrees[neighbourIndex], positionIndex)` keeps crossings with an allowed letter.
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

var scanPos = 0

proc skipWhitespace(data: string, pos: var int) =
  while pos < data.len and data[pos] <= ' ':
    inc pos

proc nextInt(data: string, pos: var int): int =
  skipWhitespace(data, pos)
  result = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    result = result * 10 + (int(data[pos]) - firstDigitCode)
    inc pos

proc readWord(data: string, pos: var int): tuple[start: int, length: int] =
  skipWhitespace(data, pos)
  result.start = pos
  while pos < data.len and data[pos] >= 'a' and data[pos] <= 'z':
    inc pos
  result.length = pos - result.start
```

Five constants set the block size and the alphabet. The read loop builds one input buffer. The scanner walks that buffer by index. No token is copied.

```nim
proc bitAdd(tree: var seq[int], index: int) =
  var idx = index
  while idx < tree.len:
    tree[idx] += 1
    idx += idx and (-idx)

proc bitSum(tree: var seq[int], index: int): int =
  var idx = index
  result = 0
  while idx > 0:
    result += tree[idx]
    idx -= idx and (-idx)
```

`idx and (-idx)` selects the lowest set bit. Each loop runs once per bit. A 100,000 slot tree has about 17 levels.

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
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let sourceWord = readWord(inputData, scanPos)
  let targetWord = readWord(inputData, scanPos)
  let pairCount = nextInt(inputData, scanPos)

  var adjacencyMask: array[letterKinds, int]
  for pairIndex in 0 .. pairCount - 1:
    skipWhitespace(inputData, scanPos)
    let leftLetter = int(inputData[scanPos]) - firstLetterCode
    inc scanPos
    skipWhitespace(inputData, scanPos)
    let rightLetter = int(inputData[scanPos]) - firstLetterCode
    inc scanPos
    adjacencyMask[leftLetter] = adjacencyMask[leftLetter] or (1 shl rightLetter)
    adjacencyMask[rightLetter] = adjacencyMask[rightLetter] or (1 shl leftLetter)

  var possible = true
  var sourceFreq: array[letterKinds, int]
  var targetFreq: array[letterKinds, int]
  for offset in 0 .. sourceWord.length - 1:
    inc sourceFreq[int(inputData[sourceWord.start + offset]) - firstLetterCode]
  for offset in 0 .. targetWord.length - 1:
    inc targetFreq[int(inputData[targetWord.start + offset]) - firstLetterCode]
  for letterIndex in 0 .. letterKinds - 1:
    if sourceFreq[letterIndex] != targetFreq[letterIndex]:
      possible = false
```

The pair loop runs `pairCount` times. Each pair sets both bitmap directions. The frequency check rejects mismatched rows before any tree work.

```nim
  var answer: int64 = 0
  if possible and sourceWord.length > 0:
    var positionLists: array[letterKinds, seq[int]]
    for letterIndex in 0 .. letterKinds - 1:
      positionLists[letterIndex] = newSeq[int](targetFreq[letterIndex])
    var filled: array[letterKinds, int]
    for offset in 0 .. targetWord.length - 1:
      let letterIndex = int(inputData[targetWord.start + offset]) - firstLetterCode
      positionLists[letterIndex][filled[letterIndex]] = offset
      inc filled[letterIndex]

    var targetIndexAt = newSeq[int](sourceWord.length)
    for letterIndex in 0 .. letterKinds - 1:
      filled[letterIndex] = 0
    for offset in 0 .. sourceWord.length - 1:
      let letterIndex = int(inputData[sourceWord.start + offset]) - firstLetterCode
      targetIndexAt[offset] = positionLists[letterIndex][filled[letterIndex]]
      inc filled[letterIndex]

    var connectedNeighbours: array[letterKinds, seq[int]]
    for letterIndex in 0 .. letterKinds - 1:
      connectedNeighbours[letterIndex] = newSeq[int]()
      for otherIndex in 0 .. letterKinds - 1:
        if (adjacencyMask[letterIndex] and (1 shl otherIndex)) != 0:
          connectedNeighbours[letterIndex].add(otherIndex)

    var totalTree = newSeq[int](sourceWord.length + 1)
    var letterTrees: array[letterKinds, seq[int]]
    var letterTotals: array[letterKinds, int]
    for letterIndex in 0 .. letterKinds - 1:
      letterTrees[letterIndex] = newSeq[int](sourceWord.length + 1)
```

These loops run once per brick or once per letter. `positionLists` stores target slots in occurrence order. Each tree starts empty with one slot per brick.

```nim
    for offset in 0 .. sourceWord.length - 1:
      let letterIndex = int(inputData[sourceWord.start + offset]) - firstLetterCode
      let positionIndex = targetIndexAt[offset] + 1
      let allInversions = offset - bitSum(totalTree, positionIndex)
      var connectedInversions = 0
      for neighbourIndex in connectedNeighbours[letterIndex]:
        connectedInversions += letterTotals[neighbourIndex] - bitSum(letterTrees[neighbourIndex], positionIndex)
      if connectedInversions != allInversions:
        possible = false
        break
      answer += int64(connectedInversions)
      bitAdd(totalTree, positionIndex)
      bitAdd(letterTrees[letterIndex], positionIndex)
      inc letterTotals[letterIndex]

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

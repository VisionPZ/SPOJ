## Problem

Read a list of data sets. Each set gives n and n keys in prefix order; the keys describe a binary search tree whose keys run from 1 to n. Count the permutations of those keys whose insertion builds exactly that tree. Write one count per line.

Input and answer bounds set the size of the program's work.

| Item | Bound |
| --- | --- |
| Data sets | at most 10 |
| Tree keys | from 1 to 30 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The largest answer has 22 digits, so one machine integer cannot hold it.

## Idea

The first inserted key becomes the root, so every valid permutation starts with that key. Keys for the left and right subtrees then interleave, and C(L+R, L) counts their interleavings. Multiply that factor by the subtree counts and recurse down the prefix sequence.

Cost per node: one binomial coefficient and one multiply of a three-limb integer.

## Why It Works

Inserting keys into an empty search tree fixes the root as the first key. Every smaller key goes left and every larger key goes right, so the two subtree key sets are fixed. An interleaving keeps the relative order inside each subtree, so each interleaving yields a distinct valid permutation.

The recursion multiplies counts for independent choices, which gives the product formula. C(L+R, L) counts the ways to choose L positions for left keys among L+R positions.

The prefix sequence splits by key ranges, not by a stored child list.

- `startIndex` points at the root key of the current subtree.
- `pivotKey` is the key at `startIndex`, and it roots the current subtree.
- `leftKeyCount = pivotKey - lowKey` counts the smaller keys in the current interval.
- `rightKeyCount = highKey - pivotKey` counts the larger keys in the current interval.
- `startIndex + 1 + leftKeyCount` points at the first key of the right subtree prefix.
- `leftKeyCount + rightKeyCount` is the group size for the binomial coefficient.

The sample tree with keys 2, 1, 3 gives this trace.

| Pivot | Left keys | Right keys | Interleavings | Running product |
| --- | --- | --- | --- | --- |
| 1 | 0 | 0 | 1 | 1 |
| 3 | 0 | 0 | 1 | 1 |
| 2 | 1 | 1 | 2 | 2 |

The factors multiply to 2, which matches the sample.

## Code

The scanner reads one buffered copy of the input and advances a single cursor.

```nim
const baseValue = 1000000000
const flushBlockBytes = 1 shl 18
const firstDigitValue = 48
const limbDigitCount = 9

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var numberValue = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    numberValue = numberValue * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return numberValue
```

The scanner walks `inputData` once, so `scanPos` never resets between numbers. Its loops run once per digit of a token, which is at most two here. Skipping non-digits absorbs spaces and newlines without building token objects.

The recursion collects one interleaving factor per node.

```nim
proc binomialCoefficient(groupSize: int, chooseCount: int): int =
  var coefficient = 1
  for step in 1 .. chooseCount:
    coefficient = coefficient * (groupSize - chooseCount + step) div step
  return coefficient

proc collectInterleaveFactors(prefixKeys: seq[int], startIndex: int, lowKey: int, highKey: int, factors: var seq[int]) =
  let pivotKey = prefixKeys[startIndex]
  let leftKeyCount = pivotKey - lowKey
  let rightKeyCount = highKey - pivotKey
  if leftKeyCount > 0:
    collectInterleaveFactors(prefixKeys, startIndex + 1, lowKey, pivotKey - 1, factors)
  if rightKeyCount > 0:
    collectInterleaveFactors(prefixKeys, startIndex + 1 + leftKeyCount, pivotKey + 1, highKey, factors)
  factors.add binomialCoefficient(leftKeyCount + rightKeyCount, leftKeyCount)
```

The `step` loop runs `chooseCount` times, and `chooseCount` is at most 14. Dividing inside the loop keeps each intermediate value exact and small. The right subtree starts after exactly `leftKeyCount` keys, which avoids reading a child as a sibling.

The product grows one decimal limb at a time.

```nim
proc multiplyBySmall(bigValue: var seq[int], factor: int) =
  var carry = 0
  for limbIndex in 0 .. bigValue.high:
    let product = bigValue[limbIndex] * factor + carry
    bigValue[limbIndex] = product mod baseValue
    carry = product div baseValue
  while carry > 0:
    bigValue.add(carry mod baseValue)
    carry = carry div baseValue
```

The limb loop runs once per stored limb, at most three for this problem. The carry leaves the loop only while it still has digits, which grows the answer safely. A factor below 80 million keeps every product inside one machine word.

The printer writes the highest limb first and pads the rest.

```nim
proc appendPaddedLimb(outputBuffer: var string, limbValue: int) =
  var placeValue = 1
  for digitIndex in 1 .. limbDigitCount:
    placeValue = placeValue * 10
  var remaining = limbValue
  for digitIndex in 1 .. limbDigitCount:
    placeValue = placeValue div 10
    let digitValue = remaining div placeValue
    outputBuffer.add char(firstDigitValue + digitValue)
    remaining = remaining mod placeValue

proc appendBigAnswer(outputBuffer: var string, bigValue: seq[int]) =
  outputBuffer.add $bigValue[bigValue.high]
  for limbIndex in countdown(bigValue.high - 1, 0):
    appendPaddedLimb(outputBuffer, bigValue[limbIndex])
  outputBuffer.add '\n'
```

Both loops run `limbDigitCount` times, so the layout stays fixed at nine digits per limb. Writing the top limb without padding avoids a leading zero in the printed answer. The newline puts each data set on its own output line.

The driver parses every data set and flushes the output buffer in blocks.

```nim
var inputData = ""
var oneLine = ""
while readLine(stdin, oneLine):
  inputData.add oneLine
  inputData.add '\n'

var scanPos = 0
let dataSetCount = nextInt(inputData, scanPos)
var outputBuffer = ""
for dataSetIndex in 0 .. dataSetCount - 1:
  let treeSize = nextInt(inputData, scanPos)
  var prefixKeys = newSeq[int](treeSize)
  for keyIndex in 0 .. treeSize - 1:
    prefixKeys[keyIndex] = nextInt(inputData, scanPos)
  var interleaveFactors: seq[int] = @[]
  collectInterleaveFactors(prefixKeys, 0, 1, treeSize, interleaveFactors)
  var bigAnswer = @[1]
  for factor in interleaveFactors:
    multiplyBySmall(bigAnswer, factor)
  appendBigAnswer(outputBuffer, bigAnswer)
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

if outputBuffer.len > 0:
  stdout.write outputBuffer
```

The outer loop runs `dataSetCount` times, and the inner loop runs `treeSize` times. Reading all input first keeps parsing in one buffer and avoids a syscall per line. The buffer flushes only after `flushBlockBytes` bytes, which caps memory and write calls.

## Complexity

Parsing reads each input token once, so it costs time linear in the input length. Each tree node costs one binomial of at most 14 steps and one multiply of at most three limbs. A data set has n nodes, so its work is O(n) with a small constant.

The phases and their costs are as follows.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(input length) | O(input length) |
| Factor collection | O(n) | O(n) for factors |
| Big-integer product | O(n) | O(1) for three limbs |
| Output | O(output length) | O(1) block buffer |

Total time is O(total input length plus total output length), and total space is O(input length). A naive check enumerates all n! permutations and rebuilds a tree for each one, which grows far faster than this count.

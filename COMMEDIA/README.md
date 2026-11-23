## Problem

Read several three-dimensional sliding puzzles. Each puzzle is a cube of `M × M × M` slots containing numbered tiles and one empty slot marked zero. A move slides a neighbouring tile into the empty slot. Decide whether the given arrangement can reach the solved arrangement. Print one sentence per puzzle.

| Quantity | Bound |
| --- | --- |
| Puzzles per file | not fixed |
| Cube side `M` | 1 to 100 |
| Slots per puzzle | up to 1,000,000 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

A naive search of arrangements is impossible, so the answer comes from a parity invariant.

## Idea

Count inversions of the tile sequence after replacing the empty slot with the largest tile number. Add the parity of the empty slot's coordinate sum. Compare the result with the coordinate sum of the solved empty slot. Equal parities mean the puzzle is solvable.

Counting inversions with a Fenwick tree costs O(N log N) for N slots. Counting them by pairwise comparison would cost O(N²).

## Why It Works

Every move exchanges the empty slot with one tile. In the full sequence of tiles plus the empty marker, that exchange changes the permutation parity. The same move changes exactly one coordinate of the empty slot by one, so the coordinate-sum parity also changes. Their sum therefore stays constant.

In the solved arrangement the permutation is the identity and the empty slot sits at `(M−1, M−1, M−1)`. Its coordinate sum is `3(M−1)`. The test is:

- `inversion parity + empty coordinate parity ≡ 3(M−1) (mod 2)`

The linear slot index is `x + M·y + M²·z`, so the three coordinates are read with one division and two remainders.

## Code

The input goes into one buffer and a digit scanner supplies the integers.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const solvableMessage = "Puzzle can be solved."
const unsolvableMessage = "Puzzle is unsolvable."

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value
```

All tile numbers are non-negative, so the scanner needs no sign branch. Parsing one number visits each digit once.

The Fenwick tree counts inversions in one pass and records the empty slot.

```nim
var fenwickTree: seq[int]

proc addValue(treeIndex: int, delta: int) =
  var index = treeIndex
  while index < fenwickTree.len:
    fenwickTree[index] += delta
    index += index and -index

proc prefixSum(treeIndex: int): int =
  var total = 0
  var index = treeIndex
  while index > 0:
    total += fenwickTree[index]
    index -= index and -index
  return total

proc permutationParity(slotCount: int, blankValue: int, blankIndex: var int): int =
  fenwickTree = newSeq[int](slotCount + 1)
  var parity = 0
  for slotIndex in 0..<slotCount:
    let tileValue = nextInt(inputData, scanPos)
    if tileValue == 0:
      blankIndex = slotIndex
    let sequenceValue = if tileValue == 0: blankValue else: tileValue
    parity = (parity + (slotIndex - prefixSum(sequenceValue))) and 1
    addValue(sequenceValue, 1)
  return parity
```

At slot `slotIndex`, the number of earlier larger values is `slotIndex − prefixSum(value)`. Only parity matters, so the tree stores counts and the accumulator keeps one bit. The empty marker uses the largest value and lands last in the solved sequence.

The driver converts the empty index to coordinates and applies the test.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1..caseCount:
  let sideLength = nextInt(inputData, scanPos)
  let slotCount = sideLength * sideLength * sideLength
  var blankIndex = 0
  let parity = permutationParity(slotCount, slotCount, blankIndex)
  let coordinateX = blankIndex mod sideLength
  let coordinateY = (blankIndex div sideLength) mod sideLength
  let coordinateZ = blankIndex div (sideLength * sideLength)
  let blankCoordinateParity = (coordinateX + coordinateY + coordinateZ) and 1
  let solvedCoordinateParity = (3 * (sideLength - 1)) and 1
  if ((parity + blankCoordinateParity) and 1) == solvedCoordinateParity:
    appendOutput(solvableMessage)
  else:
    appendOutput(unsolvableMessage)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The tree is rebuilt per puzzle because the slot count can change. Output is written in blocks rather than one call per puzzle.

## Complexity

Reading and inversion counting take O(N log N) time and O(N) space for N slots. Coordinate work and output take O(1) per puzzle. Total time is O(N log N) per puzzle and total space is O(N). Pairwise inversion counting would take O(N²) and fail at the largest cube.

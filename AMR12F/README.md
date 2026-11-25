# AMR12F — Denethors Decryption of Dequeue Permutations (SPOJ)

<https://www.spoj.com/problems/AMR12F/>

## Problem

A deque holding `1` to `N` is emptied by repeatedly taking its front or back. The resulting order is a deque permutation, and its rank counts how many deque permutations sort earlier. Given some positions and values in the first `N/2` entries, report the smallest and largest rank still possible after each new clue.

Input starts with `T`, the test count. Each case starts with `N`, followed by exactly `floor(N/2)` lines with two integers `i` and `j`. Each line says the `i`-th entry equals `j`. Output one line per clue: `-1` if the clues cannot hold together, or two integers giving the minimum and maximum rank modulo 1000000007.

| item | bound |
|---|---|
| test cases `T` | 1 or 2 |
| army size `N` | 2 to 100000 |
| revealed positions `i` | 1 to `floor(N/2)` |
| revealed values `j` | 1 to `N` |
| judge limit | 8000 ms, 1536 MB |

Positions and values never repeat inside a case. Ranks start at zero.

Sample input:

```
2
3
1 3
32
1 1
3 2
2 32
4 4
5 5
6 6
7 7
8 8
9 9
10 10
11 11
12 12
13 13
14 14
15 15
16 3
```

Sample output:

```
2 3
0 73741816
536870912 805306367
536870912 805306367
-1
-1
-1
-1
-1
-1
-1
-1
-1
-1
-1
-1
-1
```

## Idea

Think of each deque pop as choosing the left or right end of a row of cards, like dealing from either end of a deck. A clue pins one pop choice and how many back pops came before it. Rank is a sum of powers of two over back pops, so the smallest and largest ranks come from delaying or advancing those back pops inside each gap between clues. A segment tree holds the two weighted sums, and a Fenwick tree finds the neighboring clues.

Enumerating all 2^(N/2) prefixes after every clue costs exponential time. The tree updates take logarithmic time per clue with a fixed number of range changes. The takeaway is that the visible prefix alone decides the rank interval.

## Why It Works

1. At entry `t`, the deque holds `N - t + 1` consecutive values.
2. Taking the back there makes `2^(N-t-1)` smaller permutations sort before it.
3. A fixed visible prefix occupies ranks from its back-pop sum up to that sum plus `2^(N-h-1) - 1`.
4. A clue with `j <= i` forces a front pop with `i - j` back pops before it.
5. A clue with `j >= N - i + 1` forces a back pop with `N - j` back pops before it.
6. Values between those ranges cannot occur, so the clues contradict each other.
7. Two consecutive clues need a back-count increase between zero and the number of positions between them.
8. Delaying required back pops gives the smallest rank sum; advancing them gives the largest.

| term | meaning |
|---|---|
| `segmentLength` | number of revealed positions, `floor(N/2)` |
| `powerOfTwo` | powers of two used as rank weights |
| `prefixWeight` | prefix sums of the weights |
| `backsBefore` | back pops before the current position |
| `firstIncrease` | back pops required before the new clue |
| `secondIncrease` | back pops required after the new clue |
| `sumMin` | weighted sum for the smallest rank |
| `sumMax` | weighted sum for the largest rank |
| `bitTree` | Fenwick tree marking revealed positions |

The table names the values that drive the rank bounds.

A script trace of the second sample case follows, with N = 32 and 16 revealed positions.

| clue | forced change | minimum rank | maximum rank |
|---|---|---|---|
| `1 = 1` | position 1 is front | 0 | 73741816 |
| `3 = 2` | position 2 is back, position 3 is front | 536870912 | 805306367 |
| `2 = 32` | no new information | 536870912 | 805306367 |
| `4 = 4` | needs 0 back pops, but 1 exists | -1 | -1 |

The first maximum equals 2^30 - 1 modulo 1000000007, since positions 2 through 16 can all be back pops.

## Code

**Input, powers, and buffered output.** All input is read once and rank weights are precomputed.

```nim
const flushBlockBytes = 1 shl 17
const answerMod = 1000000007
const maxArmySize = 100000

var powerOfTwo: array[maxArmySize + 1, int64]
powerOfTwo[0] = 1
for exponent in 1 .. maxArmySize:
  powerOfTwo[exponent] = (powerOfTwo[exponent - 1] * 2) mod answerMod

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

`powerOfTwo` holds all rank weights.
`nextInt` reads the clues from `inputData`.
`appendOutput` batches the answer lines.

**Segment tree and Fenwick tree.** Two lazy sums track the smallest and largest rank, while the Fenwick tree locates neighboring clues.

```nim
var segmentLength = 0
var prefixWeight: seq[int64]
var sumMin: seq[int64]
var sumMax: seq[int64]
var lazyMin: seq[int]
var lazyMax: seq[int]

proc applyMin(node: int, left: int, right: int, value: int) =
  if value == 1:
    sumMin[node] = prefixWeight[right] - prefixWeight[left - 1]
    if sumMin[node] < 0:
      sumMin[node] += answerMod
  else:
    sumMin[node] = 0
  lazyMin[node] = value

proc applyMax(node: int, left: int, right: int, value: int) =
  if value == 1:
    sumMax[node] = prefixWeight[right] - prefixWeight[left - 1]
    if sumMax[node] < 0:
      sumMax[node] += answerMod
  else:
    sumMax[node] = 0
  lazyMax[node] = value

proc pushDown(node: int, left: int, right: int) =
  let middle = (left + right) div 2
  if lazyMin[node] != -1:
    applyMin(node * 2, left, middle, lazyMin[node])
    applyMin(node * 2 + 1, middle + 1, right, lazyMin[node])
    lazyMin[node] = -1
  if lazyMax[node] != -1:
    applyMax(node * 2, left, middle, lazyMax[node])
    applyMax(node * 2 + 1, middle + 1, right, lazyMax[node])
    lazyMax[node] = -1

proc assignMin(node: int, left: int, right: int, queryLeft: int, queryRight: int, value: int) =
  if queryLeft > right or queryRight < left:
    return
  if queryLeft <= left and right <= queryRight:
    applyMin(node, left, right, value)
    return
  pushDown(node, left, right)
  let middle = (left + right) div 2
  assignMin(node * 2, left, middle, queryLeft, queryRight, value)
  assignMin(node * 2 + 1, middle + 1, right, queryLeft, queryRight, value)
  sumMin[node] = (sumMin[node * 2] + sumMin[node * 2 + 1]) mod answerMod

proc assignMax(node: int, left: int, right: int, queryLeft: int, queryRight: int, value: int) =
  if queryLeft > right or queryRight < left:
    return
  if queryLeft <= left and right <= queryRight:
    applyMax(node, left, right, value)
    return
  pushDown(node, left, right)
  let middle = (left + right) div 2
  assignMax(node * 2, left, middle, queryLeft, queryRight, value)
  assignMax(node * 2 + 1, middle + 1, right, queryLeft, queryRight, value)
  sumMax[node] = (sumMax[node * 2] + sumMax[node * 2 + 1]) mod answerMod

proc setMinRange(leftBound: int, rightBound: int, value: int) =
  var leftPos = leftBound
  var rightPos = rightBound
  if leftPos < 1:
    leftPos = 1
  if rightPos > segmentLength:
    rightPos = segmentLength
  if leftPos <= rightPos:
    assignMin(1, 1, segmentLength, leftPos, rightPos, value)

proc setMaxRange(leftBound: int, rightBound: int, value: int) =
  var leftPos = leftBound
  var rightPos = rightBound
  if leftPos < 1:
    leftPos = 1
  if rightPos > segmentLength:
    rightPos = segmentLength
  if leftPos <= rightPos:
    assignMax(1, 1, segmentLength, leftPos, rightPos, value)

var bitTree: seq[int]

proc bitAdd(position: int) =
  var pos = position
  while pos <= segmentLength:
    bitTree[pos] += 1
    pos += pos and -pos

proc bitPrefix(position: int): int =
  var pos = position
  var total = 0
  while pos > 0:
    total += bitTree[pos]
    pos -= pos and -pos
  return total

proc bitFindKth(rank: int): int =
  var remaining = rank
  var pos = 0
  var step = 1
  while step shl 1 <= segmentLength:
    step = step shl 1
  while step > 0:
    let nextPos = pos + step
    if nextPos <= segmentLength and bitTree[nextPos] < remaining:
      pos = nextPos
      remaining -= bitTree[nextPos]
    step = step div 2
  return pos + 1
```

`assignMin` and `assignMax` set a range of pop choices to 0 or 1.
`setMinRange` and `setMaxRange` clip ranges to the visible prefix.
`bitFindKth` recovers a neighboring clue by rank.

**Clue processing and rank output.** Each clue is classified, checked, inserted, and applied to both rank trees.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let armySize = nextInt(inputData, scanPos)
  segmentLength = armySize div 2
  prefixWeight = newSeq[int64](segmentLength + 2)
  for position in 1 .. segmentLength:
    let exponent = armySize - position - 1
    prefixWeight[position] = (prefixWeight[position - 1] + powerOfTwo[exponent]) mod answerMod
  prefixWeight[segmentLength + 1] = prefixWeight[segmentLength]
  sumMin = newSeq[int64](4 * segmentLength + 5)
  sumMax = newSeq[int64](4 * segmentLength + 5)
  lazyMin = newSeq[int](4 * segmentLength + 5)
  lazyMax = newSeq[int](4 * segmentLength + 5)
  for cellIndex in 0 .. 4 * segmentLength + 4:
    lazyMin[cellIndex] = -1
    lazyMax[cellIndex] = -1
  bitTree = newSeq[int](segmentLength + 1)
  var requiredBacks = newSeq[int](segmentLength + 1)
  var isBackChoice = newSeq[bool](segmentLength + 1)
  var inconsistent = false
  for pairIndex in 0 .. segmentLength - 1:
    let position = nextInt(inputData, scanPos)
    let value = nextInt(inputData, scanPos)
    if inconsistent:
      appendOutput("-1\n")
      continue
    var choiceBack = false
    var backsBefore = 0
    if value <= position:
      backsBefore = position - value
    elif value >= armySize - position + 1:
      choiceBack = true
      backsBefore = armySize - value
    else:
      inconsistent = true
      appendOutput("-1\n")
      continue
    if bitPrefix(position) - bitPrefix(position - 1) != 0:
      inconsistent = true
      appendOutput("-1\n")
      continue
    let countBefore = bitPrefix(position - 1)
    var predecessor = 0
    if countBefore > 0:
      predecessor = bitFindKth(countBefore)
    var successor = segmentLength + 1
    if bitPrefix(segmentLength) > countBefore:
      successor = bitFindKth(countBefore + 1)
    let backsAfterPredecessor = if predecessor == 0: 0 else:
      requiredBacks[predecessor] + (if isBackChoice[predecessor]: 1 else: 0)
    let firstIncrease = backsBefore - backsAfterPredecessor
    if firstIncrease < 0 or firstIncrease > position - 1 - predecessor:
      inconsistent = true
      appendOutput("-1\n")
      continue
    var secondIncrease = 0
    if successor <= segmentLength:
      secondIncrease = requiredBacks[successor] - (backsBefore + (if choiceBack: 1 else: 0))
      if secondIncrease < 0 or secondIncrease > successor - 1 - position:
        inconsistent = true
        appendOutput("-1\n")
        continue
    bitAdd(position)
    requiredBacks[position] = backsBefore
    isBackChoice[position] = choiceBack
    setMinRange(predecessor + 1, position - firstIncrease - 1, 0)
    setMinRange(position - firstIncrease, position - 1, 1)
    setMaxRange(predecessor + 1, predecessor + firstIncrease, 1)
    setMaxRange(predecessor + firstIncrease + 1, position - 1, 0)
    setMinRange(position, position, if choiceBack: 1 else: 0)
    setMaxRange(position, position, if choiceBack: 1 else: 0)
    if successor == segmentLength + 1:
      setMinRange(position + 1, segmentLength, 0)
      setMaxRange(position + 1, segmentLength, 1)
    else:
      setMinRange(position + 1, successor - secondIncrease - 1, 0)
      setMinRange(successor - secondIncrease, successor - 1, 1)
      setMaxRange(position + 1, position + secondIncrease, 1)
      setMaxRange(position + secondIncrease + 1, successor - 1, 0)
    let minValue = sumMin[1]
    let tailSize = powerOfTwo[armySize - segmentLength - 1]
    let maxValue = (sumMax[1] + tailSize - 1) mod answerMod
    appendOutput($minValue & " " & $maxValue)
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`firstIncrease` and `secondIncrease` check neighboring clues.
`requiredBacks` and `isBackChoice` store each accepted clue.
`minValue` and `maxValue` combine the tree sums with the free tail.

## Complexity

Each clue triggers a constant number of logarithmic tree updates.

| phase | time | space |
|---|---|---|
| power precompute | 100000 steps | one power array |
| clue classification | O(log h) Fenwick work | two clue arrays |
| rank updates | O(log h) per changed range | two segment trees |
| output | one line per clue | block buffer |

| measure | Big O |
|---|---|
| time per case | O(h log h) |
| extra space | O(h) |

Enumerating every visible prefix after each clue costs O(h × 2^h) and cannot fit the upper bound. The two trees keep the rank interval current with logarithmic work per clue.

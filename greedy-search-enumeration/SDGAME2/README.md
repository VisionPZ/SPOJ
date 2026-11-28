# SDGAME2 — Another understanding of Super Dice Game (SPOJ)

<https://www.spoj.com/problems/SDGAME2/>

## Problem

Two players move around a circular track using products of dice values. After each roll, print the position of the player who rolled.

Input has one case: `R N M`, then `R` lines of `d v a b`. Roll `d` sets die `d` to value `v`.

The move is the product of available dice from index `a` through `b`. If none is available, the move is one space.

Output has `R` lines, each a position modulo `M`.

The bounds from the statement:

| item | bound |
|---|---|
| rolls R | 1 to 100000 |
| dice N | 1 to 10000 |
| cells M | 2 to 1000000000 |
| die values | 0 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

A die with value above 1000000000 is unavailable; multiplying by cell zero restores value zero.

Sample input:

```
6 4 4
0 1000000000 1 1
1 999999998 1 1
2 500000000 3 3
0 1 2 2
3 1 0 3
0 6 0 3
```

This figure is the sample input copied from the statement.

Sample output:

```
1
2
2
2
0
0
```

This figure is the sample output, one position per roll.

## Idea

Treat the dice as a row of numbered tiles and keep a running product for each stretch of tiles.

A segment tree answers each stretch query and each value change in logarithmic time.

When both players meet, every tile gets multiplied by the shared cell, so track only the tiles still able to affect a product.

Scanning all dice on every meeting costs far more than touching the shrinking active set. The tree keeps products current with a small amount of work per change.

## Why It Works

1. A die is available when its value lies between zero and 1000000000.
2. The move distance is the product of available dice in the queried range, taken modulo `M`.
3. Unavailable dice contribute a factor of one to the product and never appear in the active set.
4. Multiplying a positive cell keeps every unavailable die unavailable, since its value only grows.
5. Multiplying by cell zero sets every die to zero, handled by one lazy tag and one epoch bump.
6. Each still available nonzero die at least doubles under a positive multiplier, so it leaves the active set after a bounded number of meetings.

The main terms:

| term | meaning |
|---|---|
| `segmentProduct` | product of available dice in a tree node, modulo `M` |
| `segmentAvailable` | count of available dice in a tree node |
| `activeDice` | indexes of dice with positive available values |
| `zeroEpoch` | generation number that invalidates stale active slots after cell zero |

The table names the structures that keep the simulation cheap.

A script traced the sample rolls:

```
roll 1: dice [1e9,1,1,1], move 1, Alice 1
roll 2: dice [1e9,999999998,1,1], move 999999998 mod 4 = 2, Bob 2
roll 3: dice [1e9,999999998,5e8,1], move 1, Alice 2
meet at 2: dice [*,*,1e9,2], * means unavailable
roll 4: dice [1,*,1e9,2], move 1e9 mod 4 = 0, Bob 2
meet at 2: dice [2,*,*,4]
roll 5: dice [2,*,*,1], move 2*1 mod 4 = 2, Alice 0
roll 6: dice [6,*,*,1], move 6*1 mod 4 = 2, Bob 0
```

The printed positions 1, 2, 2, 2, 0, 0 match the sample output.

Products stay below 1000000000 before multiplication, so a pairwise product fits in a signed 64-bit integer. The sentinel `unavailableValue` marks values above the legal range without storing huge integers.

## Code

**Input and scanner.** The reader loads all roll lines, and the scanner walks integer tokens.

```nim
const flushBlockBytes = 1 shl 17
const unavailableValue = 1000000001

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

One case starts with three header values.
Every roll contributes four integers.
The output buffer flushes in blocks.

**Segment tree.** Nodes hold products and availability counts, with a lazy tag for cell zero.

```nim
let rollCount = nextInt(inputData, scanPos)
let diceCount = nextInt(inputData, scanPos)
let cellCount = nextInt(inputData, scanPos)

var segmentProduct = newSeq[int64](4 * diceCount)
var segmentAvailable = newSeq[int](4 * diceCount)
var zeroTag = newSeq[int](4 * diceCount)
for tagIndex in 0 .. zeroTag.len - 1:
  zeroTag[tagIndex] = -1
  segmentProduct[tagIndex] = 1
  segmentAvailable[tagIndex] = 1

proc applyZero(nodeIndex: int, firstCell, lastCell: int) =
  segmentProduct[nodeIndex] = 0
  segmentAvailable[nodeIndex] = lastCell - firstCell + 1
  zeroTag[nodeIndex] = 0

proc pushTag(nodeIndex: int, firstCell, lastCell: int) =
  if zeroTag[nodeIndex] == 0 and firstCell < lastCell:
    let middleCell = (firstCell + lastCell) div 2
    applyZero(nodeIndex * 2, firstCell, middleCell)
    applyZero(nodeIndex * 2 + 1, middleCell + 1, lastCell)
    zeroTag[nodeIndex] = -1

proc assignDie(nodeIndex, firstCell, lastCell, dieIndex, assignedProduct: int, available: bool) =
  if firstCell == lastCell:
    segmentProduct[nodeIndex] = int64(assignedProduct)
    segmentAvailable[nodeIndex] = 0
    if available:
      segmentAvailable[nodeIndex] = 1
    zeroTag[nodeIndex] = -1
    return
  pushTag(nodeIndex, firstCell, lastCell)
  let middleCell = (firstCell + lastCell) div 2
  if dieIndex <= middleCell:
    assignDie(nodeIndex * 2, firstCell, middleCell, dieIndex, assignedProduct, available)
  else:
    assignDie(nodeIndex * 2 + 1, middleCell + 1, lastCell, dieIndex, assignedProduct, available)
  segmentProduct[nodeIndex] = (segmentProduct[nodeIndex * 2] * segmentProduct[nodeIndex * 2 + 1]) mod int64(cellCount)
  segmentAvailable[nodeIndex] = segmentAvailable[nodeIndex * 2] + segmentAvailable[nodeIndex * 2 + 1]

var queryProduct: int64 = 1
var queryAvailable = 0

proc queryRange(nodeIndex, firstCell, lastCell, queryFirst, queryLast: int) =
  if queryFirst <= firstCell and lastCell <= queryLast:
    queryProduct = (queryProduct * segmentProduct[nodeIndex]) mod int64(cellCount)
    queryAvailable += segmentAvailable[nodeIndex]
    return
  pushTag(nodeIndex, firstCell, lastCell)
  let middleCell = (firstCell + lastCell) div 2
  if queryFirst <= middleCell:
    queryRange(nodeIndex * 2, firstCell, middleCell, queryFirst, queryLast)
  if queryLast > middleCell:
    queryRange(nodeIndex * 2 + 1, middleCell + 1, lastCell, queryFirst, queryLast)
```

Each die update changes one leaf and its ancestors.
A range query multiplies whole covered nodes modulo `M`.
The zero tag sets an entire subtree without visiting its leaves.

**Active dice list.** Positive available dice live in a swappable list with generation stamps.

```nim
var dieValues = newSeq[int64](diceCount)
var activeSlots = newSeq[int](diceCount)
var activeEpochs = newSeq[int](diceCount)
var activeDice = newSeq[int](diceCount)
var activeCount = 0
var zeroEpoch = 0
for dieIndex in 0 .. diceCount - 1:
  dieValues[dieIndex] = 1
  activeSlots[dieIndex] = -1
  activeEpochs[dieIndex] = -1
  activeDice[dieIndex] = dieIndex

proc removeActive(dieIndex: int) =
  let slotIndex = activeSlots[dieIndex]
  if slotIndex < 0 or activeEpochs[dieIndex] != zeroEpoch:
    return
  let lastSlot = activeCount - 1
  let swappedDie = activeDice[lastSlot]
  activeDice[slotIndex] = swappedDie
  activeSlots[swappedDie] = slotIndex
  activeCount = lastSlot
  activeSlots[dieIndex] = -1

proc addActive(dieIndex: int) =
  if activeSlots[dieIndex] >= 0 and activeEpochs[dieIndex] == zeroEpoch:
    return
  activeEpochs[dieIndex] = zeroEpoch
  activeSlots[dieIndex] = activeCount
  activeDice[activeCount] = dieIndex
  activeCount += 1
```

Swapping with the last entry removes a die in constant time.
The epoch check discards slots left over from a cell zero.
Only positive available values enter this list.

**Roll loop.** Each roll updates one die, queries its range, moves a player, and applies a meeting.

```nim
var alicePosition: int64 = 0
var bobPosition: int64 = 0
var aliceTurn = true

for rollIndex in 0 .. rollCount - 1:
  let dieIndex = nextInt(inputData, scanPos)
  let shownValue = nextInt(inputData, scanPos)
  let rangeFirst = nextInt(inputData, scanPos)
  let rangeLast = nextInt(inputData, scanPos)

  dieValues[dieIndex] = int64(shownValue)
  if shownValue > 0:
    addActive(dieIndex)
    assignDie(1, 0, diceCount - 1, dieIndex, shownValue mod cellCount, true)
  else:
    removeActive(dieIndex)
    assignDie(1, 0, diceCount - 1, dieIndex, 0, true)

  queryProduct = 1
  queryAvailable = 0
  queryRange(1, 0, diceCount - 1, rangeFirst, rangeLast)
  var moveDistance: int64 = 1
  if queryAvailable > 0:
    moveDistance = queryProduct

  var rolledPosition: int64 = 0
  if aliceTurn:
    alicePosition = (alicePosition + moveDistance) mod int64(cellCount)
    rolledPosition = alicePosition
  else:
    bobPosition = (bobPosition + moveDistance) mod int64(cellCount)
    rolledPosition = bobPosition
  appendOutput($rolledPosition)
  outputBuffer.add '\n'

  if alicePosition == bobPosition:
    let multiplier = alicePosition
    if multiplier == 0:
      zeroEpoch += 1
      activeCount = 0
      applyZero(1, 0, diceCount - 1)
    else:
      var activeIndex = 0
      while activeIndex < activeCount:
        let currentDie = activeDice[activeIndex]
        let newValue = dieValues[currentDie] * multiplier
        if newValue > int64(unavailableValue - 1):
          dieValues[currentDie] = int64(unavailableValue)
          assignDie(1, 0, diceCount - 1, currentDie, 1, false)
          removeActive(currentDie)
        else:
          dieValues[currentDie] = newValue
          assignDie(1, 0, diceCount - 1, currentDie, int(newValue mod int64(cellCount)), true)
          activeIndex += 1
  aliceTurn = not aliceTurn

stdout.write outputBuffer
outputBuffer.setLen 0
```

The die is set before the range is queried.
Cell zero clears every die with one tag and one epoch bump.
A meeting with a positive cell retires dice that cross the value limit.

## Complexity

Each roll performs one point update, one range query, and a bounded amount of meeting work.

The cost breakdown by phase:

| phase | time | space |
|---|---|---|
| input read | one pass over roll lines | one input string |
| die update | O(log N) per roll | four arrays of N nodes |
| range query | O(log N) per roll | query accumulators |
| meetings | O(log N) per changed die | active list of N dice |
| output | one line per roll | block buffer |

The tree operations dominate all other phases.

The overall asymptotic bounds:

| measure | Big O |
|---|---|
| time | O(R log N) |
| space | O(N) |

Rescanning all dice after every meeting costs O(R * N), while the active list avoids that work.

# SDGAME — Super Dice Game (SPOJ)

<https://www.spoj.com/problems/SDGAME/>

## Problem

Track two players on a circular track after dice rolls, range products, and shared-cell multipliers. Only the new cell of the player who rolled is printed each turn.

Input begins with R, N, and M: turn count, dice count, and track size. Each of the R lines contains d, v, a, b. Die d is set to v, and the move distance is the product of dice a through b.

Players alternate turns starting with Alice, and both start at cell 0. When both share a cell after a turn, every die value is multiplied by that cell number.

| item | bound |
|---|---|
| turns R | 1 to 100000 |
| dice N | 1 to 10000 |
| track cells M | 2 to 1000000000 |
| rolled value v | 0 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

Large ranges and many turns rule out scanning dice on every turn.

Sample input:

```
6 4 20
1 5 1 1
3 10 2 3
2 3 0 3
1 2 0 3
1 5 1 2
0 7 0 1
```

Sample output:

```
5
10
15
10
10
0
```

## Idea

Keep only remainders, like a shop clerk who totals prices using their last digits. A range product modulo M needs only each die modulo M. A segment tree stores those products and supports point replacement plus range query in O(log N).

A shared cell multiplies every die, and lazy tags defer that work. Scanning the range costs O(N) per turn, which is far too slow for 100000 turns. One tree update and one tree query keep each turn small.

## Why It Works

1. The move distance is needed only modulo M.
2. A product of remainders modulo M equals the remainder of the product.
3. Each die is stored modulo M, so a roll stores v modulo M.
4. A node stores the product of its whole segment modulo M.
5. A shared cell c multiplies a segment product by c raised to the segment length.
6. Lazy tags carry the per-die factor down to children when a node is visited.

The shared-cell exponent is the trap that a plain product factor misses.

| term | meaning |
|---|---|
| `segmentTree` | product of each segment modulo M |
| `pendingFactor` | per-die multiplier waiting for children |
| `powerMod` | modular power used for segment products |
| `moveDistance` | range product for the current turn |

Every node keeps its product correct for its full segment.

A trace of the sample turns:

```
turn  roll     range product   mover  cell   collision
1     die1=5   5               Alice  5      no
2     die3=10  10              Bob    10     no
3     die2=3   150 mod 20 =10  Alice  15     no
4     die1=2   60 mod 20 =0    Bob    10     no
5     die1=5   15              Alice  10     yes, multiply by 10
6     die0=7   350 mod 20 =10  Bob    0      no
```

After turn 5, dice read 10, 50, 30, 100, exactly as in the statement. The range 2 to 3 product changes from 30 mod 20 to 30 times 100 mod 20, since two dice each gained a factor of 10.

## Code

**Input and modular power.** Values are read once, and powers use fast squaring.

```nim
const flushBlockBytes = 1 shl 17

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

let turnCount = nextInt(inputData, scanPos)
let diceCount = nextInt(inputData, scanPos)
let trackCells = int64(nextInt(inputData, scanPos))

proc powerMod(baseValue: int64, exponent: int, modulusValue: int64): int64 =
  var resultValue: int64 = 1 mod modulusValue
  var runningPower = baseValue mod modulusValue
  var remaining = exponent
  while remaining > 0:
    if (remaining and 1) == 1:
      resultValue = (resultValue * runningPower) mod modulusValue
    runningPower = (runningPower * runningPower) mod modulusValue
    remaining = remaining shr 1
  return resultValue
```

The scanner skips whitespace. Squaring needs about 14 steps for 10000 dice. Products stay inside 64-bit integers.

**Lazy multiplier and tree build.** The tag scales a node product by a power.

```nim
proc applyMultiplier(nodeIndex: int, factor: int64, segmentLength: int,
                     segmentTree: var seq[int64],
                     pendingFactor: var seq[int64], modulusValue: int64) =
  let productFactor = powerMod(factor, segmentLength, modulusValue)
  segmentTree[nodeIndex] = (segmentTree[nodeIndex] * productFactor) mod modulusValue
  pendingFactor[nodeIndex] = (pendingFactor[nodeIndex] * factor) mod modulusValue

proc pushPending(nodeIndex: int, leftBound: int, rightBound: int,
                 segmentTree: var seq[int64],
                 pendingFactor: var seq[int64], modulusValue: int64) =
  let factor = pendingFactor[nodeIndex]
  if factor != 1:
    let middle = (leftBound + rightBound) div 2
    applyMultiplier(nodeIndex * 2, factor, middle - leftBound + 1,
                    segmentTree, pendingFactor, modulusValue)
    applyMultiplier(nodeIndex * 2 + 1, factor, rightBound - middle,
                    segmentTree, pendingFactor, modulusValue)
    pendingFactor[nodeIndex] = 1

proc buildTree(nodeIndex: int, leftBound: int, rightBound: int,
               segmentTree: var seq[int64], modulusValue: int64) =
  if leftBound == rightBound:
    segmentTree[nodeIndex] = 1 mod modulusValue
    return
  let middle = (leftBound + rightBound) div 2
  buildTree(nodeIndex * 2, leftBound, middle, segmentTree, modulusValue)
  buildTree(nodeIndex * 2 + 1, middle + 1, rightBound, segmentTree, modulusValue)
  segmentTree[nodeIndex] = (segmentTree[nodeIndex * 2] *
                            segmentTree[nodeIndex * 2 + 1]) mod modulusValue
```

The exponent equals the number of dice in the node. Children receive the per-die factor. Every leaf starts at one.

**Point replacement and range product.** Rolls replace leaves, and queries combine segments.

```nim
proc setDie(nodeIndex: int, leftBound: int, rightBound: int, targetDie: int,
            newValue: int64, segmentTree: var seq[int64],
            pendingFactor: var seq[int64], modulusValue: int64) =
  if leftBound == rightBound:
    segmentTree[nodeIndex] = newValue mod modulusValue
    pendingFactor[nodeIndex] = 1
    return
  pushPending(nodeIndex, leftBound, rightBound, segmentTree, pendingFactor, modulusValue)
  let middle = (leftBound + rightBound) div 2
  if targetDie <= middle:
    setDie(nodeIndex * 2, leftBound, middle, targetDie, newValue,
           segmentTree, pendingFactor, modulusValue)
  else:
    setDie(nodeIndex * 2 + 1, middle + 1, rightBound, targetDie, newValue,
           segmentTree, pendingFactor, modulusValue)
  segmentTree[nodeIndex] = (segmentTree[nodeIndex * 2] *
                            segmentTree[nodeIndex * 2 + 1]) mod modulusValue

proc queryProduct(nodeIndex: int, leftBound: int, rightBound: int,
                  queryLeft: int, queryRight: int, segmentTree: var seq[int64],
                  pendingFactor: var seq[int64], modulusValue: int64): int64 =
  if queryLeft <= leftBound and rightBound <= queryRight:
    return segmentTree[nodeIndex]
  pushPending(nodeIndex, leftBound, rightBound, segmentTree, pendingFactor, modulusValue)
  let middle = (leftBound + rightBound) div 2
  var productValue: int64 = 1
  if queryLeft <= middle:
    productValue = (productValue * queryProduct(nodeIndex * 2, leftBound, middle,
                    queryLeft, queryRight, segmentTree, pendingFactor,
                    modulusValue)) mod modulusValue
  if queryRight > middle:
    productValue = (productValue * queryProduct(nodeIndex * 2 + 1, middle + 1,
                    rightBound, queryLeft, queryRight, segmentTree,
                    pendingFactor, modulusValue)) mod modulusValue
  return productValue
```

Pending factors are pushed before descending. A leaf replacement clears its old factor. Both operations cost O(log N).

**Turn loop.** Each turn sets a die, moves a player, and checks a collision.

```nim
var segmentTree = newSeq[int64](diceCount * 4 + 4)
var pendingFactor = newSeq[int64](diceCount * 4 + 4)
for nodeIndex in 0 .. segmentTree.len - 1:
  pendingFactor[nodeIndex] = 1
buildTree(1, 0, diceCount - 1, segmentTree, trackCells)

var aliceCell: int64 = 0
var bobCell: int64 = 0
for turnIndex in 0 .. turnCount - 1:
  let rolledDie = nextInt(inputData, scanPos)
  let shownValue = int64(nextInt(inputData, scanPos))
  let rangeLeft = nextInt(inputData, scanPos)
  let rangeRight = nextInt(inputData, scanPos)
  setDie(1, 0, diceCount - 1, rolledDie, shownValue,
         segmentTree, pendingFactor, trackCells)
  let moveDistance = queryProduct(1, 0, diceCount - 1, rangeLeft, rangeRight,
                                  segmentTree, pendingFactor, trackCells)
  if (turnIndex and 1) == 0:
    aliceCell = (aliceCell + moveDistance) mod trackCells
    appendOutput($aliceCell)
  else:
    bobCell = (bobCell + moveDistance) mod trackCells
    appendOutput($bobCell)
  outputBuffer.add '\n'
  if aliceCell == bobCell:
    applyMultiplier(1, aliceCell, diceCount, segmentTree, pendingFactor, trackCells)

stdout.write outputBuffer
outputBuffer.setLen 0
```

Turns alternate by index parity. The multiplier follows the printed cell. One line is emitted per turn.

## Complexity

Each turn performs one tree update and one tree query.

| phase | time | space |
|---|---|---|
| input read | one pass over turn tokens | input string |
| tree build | N leaves and inner nodes | four arrays per die |
| each turn | two walks of O(log N) nodes | lazy tag array |
| output | one line per turn | block buffer |

The lazy tag makes a collision cost one root update.

| measure | Big O |
|---|---|
| time | O((R + N) log N) |
| space | O(N) |

Scanning each requested range costs O(RN), which cannot handle the largest input. Tree operations replace that scan with short root-to-leaf walks.

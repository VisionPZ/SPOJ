<https://www.spoj.com/problems/TKV1000/>

## Problem

Two companies own subsidiaries with market values. On each turn a company either merges two of its own subsidiaries or removes a smaller rival subsidiary. Decide which company wins with optimal play.

Input has test cases until end of file. Each case gives N, M, then N values for Takeover and M values for Buyout. Print `Case X:` followed by the winning company name.

| item | bound |
|---|---|
| subsidiary counts N, M | 1 to 100000 per case |
| each value | 1 to 10^12 |
| cross values | never equal during play |
| judge limit | 1000 ms, 1536 MB |

A hostile takeover needs a strictly larger value and removes one rival subsidiary. A friendly merge replaces two own values by their sum.

Sample input:

```
3 2
7 1 1
5 5
4 2
3 3 3 3
5 5
```

Sample output:

```
Case 1: Takeover Incorporated
Case 2: Buyout Limited
```

## Idea

Think of each company as a pile of chips where only the top two chips can make a weapon.

The real algorithm is a greedy turn simulation with two max-heaps, at O(log N) cost per turn. Searching the full game tree would explode past any practical limit. Compare the two-largest sums first, then the maxima, then merge when forced.

## Why It Works

1. A merge creates a value equal to the sum of the two largest own values.
2. If that sum beats the rival's two-largest sum, the new value outranks every rival value.
3. Such a value can remove rival subsidiaries one by one until none remain.
4. Otherwise, a larger own maximum should remove the rival maximum.
5. Removing the rival maximum cuts its future merge potential the most.
6. If neither move helps and two own subsidiaries remain, merging is the only useful action.
7. With one subsidiary and no larger value, the company passes.
8. Each action removes one subsidiary overall, so the game ends quickly.

| term | meaning |
|---|---|
| `currentMax` | largest own value |
| `opponentMax` | largest rival value |
| `currentPairSum` | sum of the two largest own values |
| `opponentPairSum` | sum of the two largest rival values |
| `ValueHeap` | max-heap holding one company's values |
| `consecutivePasses` | guard against two stalled turns |

For sample case 1, a script found `currentPairSum = 8` and `opponentPairSum = 10`.

No merge advantage exists, but `7 > 5`, so Takeover removes a 5. Buyout cannot remove 7 and passes. Takeover removes the last 5 and wins.

For sample case 2, `3 + 3 = 6 < 10`, so Takeover must merge. Buyout merges to 10 and then removes the smaller Takeover values one by one.

Values and sums reach 10^17, so the heaps store `int64`.

## Code

**Input and scanning.** All test cases are read from one string; a probe skips trailing whitespace.

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

proc hasMoreNumbers(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner handles values up to 10^12 without sign handling.
The probe lets the loop stop after the last case.
One buffer collects every result line.

**Max-heap.** Insert, remove-max, and peek-second are the only operations needed.

```nim
type ValueHeap = object
  items: seq[int64]

proc heapPush(heap: var ValueHeap, value: int64) =
  heap.items.add value
  var childIndex = heap.items.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heap.items[parentIndex] >= heap.items[childIndex]:
      break
    let childValue = heap.items[childIndex]
    heap.items[childIndex] = heap.items[parentIndex]
    heap.items[parentIndex] = childValue
    childIndex = parentIndex

proc heapPop(heap: var ValueHeap): int64 =
  result = heap.items[0]
  let lastIndex = heap.items.len - 1
  let lastValue = heap.items[lastIndex]
  heap.items.setLen lastIndex
  if lastIndex > 0:
    heap.items[0] = lastValue
    var parentIndex = 0
    while true:
      let leftIndex = parentIndex * 2 + 1
      if leftIndex >= heap.items.len:
        break
      let rightIndex = leftIndex + 1
      var largerIndex = leftIndex
      if rightIndex < heap.items.len and heap.items[rightIndex] > heap.items[leftIndex]:
        largerIndex = rightIndex
      if heap.items[parentIndex] >= heap.items[largerIndex]:
        break
      let parentValue = heap.items[parentIndex]
      heap.items[parentIndex] = heap.items[largerIndex]
      heap.items[largerIndex] = parentValue
      parentIndex = largerIndex

proc secondLargest(heap: ValueHeap): int64 =
  if heap.items.len < 2:
    return heap.items[0]
  if heap.items.len == 2:
    return heap.items[1]
  if heap.items[1] > heap.items[2]:
    return heap.items[1]
  return heap.items[2]
```

The second largest value sits among the root's two children.
Each push and pop walks one heap path.
The heap stores `int64` values from the scanner.

**One turn.** The three rules run in priority order.

```nim
proc takeTurn(current: var ValueHeap, opponent: var ValueHeap): bool =
  let currentMax = current.items[0]
  let opponentMax = opponent.items[0]
  var currentPairSum = currentMax
  if current.items.len >= 2:
    currentPairSum = currentMax + secondLargest(current)
  var opponentPairSum = opponentMax
  if opponent.items.len >= 2:
    opponentPairSum = opponentMax + secondLargest(opponent)
  if current.items.len >= 2 and currentPairSum > opponentPairSum:
    let firstValue = heapPop(current)
    let secondValue = heapPop(current)
    heapPush(current, firstValue + secondValue)
    return false
  if currentMax > opponentMax:
    discard heapPop(opponent)
    return false
  if current.items.len >= 2:
    let firstValue = heapPop(current)
    let secondValue = heapPop(current)
    heapPush(current, firstValue + secondValue)
    return false
  return true
```

A winning merge takes priority over a takeover.
A takeover removes the rival maximum.
The return value reports a pass.

**Case loop.** Turns alternate until one heap empties.

```nim
var caseNumber = 1
while hasMoreNumbers(inputData, scanPos):
  let takeoverCount = nextInt(inputData, scanPos)
  let buyoutCount = nextInt(inputData, scanPos)
  var takeoverHeap: ValueHeap
  var buyoutHeap: ValueHeap
  takeoverHeap.items = newSeq[int64](0)
  buyoutHeap.items = newSeq[int64](0)
  var takeoverIndex = 0
  while takeoverIndex < takeoverCount:
    heapPush(takeoverHeap, int64(nextInt(inputData, scanPos)))
    takeoverIndex += 1
  var buyoutIndex = 0
  while buyoutIndex < buyoutCount:
    heapPush(buyoutHeap, int64(nextInt(inputData, scanPos)))
    buyoutIndex += 1
  var takeoverTurn = true
  var consecutivePasses = 0
  while takeoverHeap.items.len > 0 and buyoutHeap.items.len > 0 and consecutivePasses < 2:
    var passed: bool
    if takeoverTurn:
      passed = takeTurn(takeoverHeap, buyoutHeap)
    else:
      passed = takeTurn(buyoutHeap, takeoverHeap)
    if passed:
      consecutivePasses += 1
    else:
      consecutivePasses = 0
    takeoverTurn = not takeoverTurn
  appendOutput("Case " & $caseNumber & ": ")
  if takeoverHeap.items.len == 0:
    appendOutput("Buyout Limited")
  else:
    appendOutput("Takeover Incorporated")
  outputBuffer.add '\n'
  caseNumber += 1
stdout.write outputBuffer
outputBuffer.setLen 0
```

An empty heap identifies the loser.
Two passes in a row end a stalled game.
The case number counts from one.

## Complexity

Heap construction and the turn loop dominate each case.

| phase | time | space |
|---|---|---|
| input read | one pass over N + M values | one input string |
| heap build | O((N + M) log(N + M)) | two heaps |
| turn loop | one heap operation per turn | constant |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| time | O((N + M) log(N + M)) |
| space | O(N + M) |

A full game-tree search would grow exponentially with the subsidiary counts.

Track two maxima, apply the three rules, and let the heaps decide.

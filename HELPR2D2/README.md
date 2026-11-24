## Problem

Each test case gives a ship capacity K, a container count n, and a sequence of container volumes. A container entry is one volume, or the letter b with a repeat count r and a volume v. The second form means r containers of volume v.

R2-D2 places every container into the lowest numbered ship with enough free space. He opens a new ship when none fits. Print the number of ships used and the total unused volume for each case.

The statement fixes these bounds:

| Quantity | Bound |
| --- | --- |
| Test cases T | at most 10 |
| Ship capacity K | at most 1000 |
| Containers per case n | 1 to 1000000 |
| Starships used | at most 100000 |
| Changes of ship | at most 100000 |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

The container count and the ship count drive the design, while the printed answer is two numbers per case.

## Idea

A segment tree (a binary tree of range maxima over ship indices) stores free space and finds the lowest fitting ship in 17 steps. Inside a block the volume stays fixed, so a ship below that volume never fits again and the program fills ships in index order. Each block costs one descent and one update per ship visited; scanning all ships for every container costs O(n times s).

## Why It Works

The greedy rule always takes the lowest numbered ship that fits. Free space only decreases, so a ship with less free space than the block volume stays unusable for the rest of that block. The program therefore visits ships in increasing index order inside a block and never revisits one.

The tree stores the maximum free space in each range of ship indices. These lines define the search and the update:

- `leftmostFitting` descends to the lowest leaf with free space at least the threshold, and returns -1 when the root maximum is smaller.
- `leftChild` holds the maximum of the left half of the current range. A left maximum of at least the threshold puts the answer in the left half.
- `updateCapacity` writes one leaf and recomputes each parent as the larger of its two children.
- `fitCount = remainingCapacity[i] div blockVolume` counts the containers that fit in one ship.
- `take` is the smaller of the remaining block count and fitCount.
- Opening a ship stores `capacity - take * blockVolume` as its free space.

The generator prints this trace for the first sample case:

| Container | Volume | Action | Ship | Remaining capacities |
| --- | --- | --- | --- | --- |
| 1 | 50 | open ship | S0 | 50 |
| 2 | 25 | reuse | S0 | 25 |
| 3 | 70 | open ship | S1 | 25, 30 |

Result: 2 ships, waste 55.

## Code

The read loop runs once per input line and appends to one buffer. The scanner skips separators and builds each integer digit by digit. The output helper writes only when the buffer reaches the flush size.

```nim
const
  maxShips = 100000
  treeSize = 1 shl 17
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

proc skipSpaces(data: string, i: var int) =
  while i < data.len and data[i] <= ' ':
    i += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The tree has one leaf per ship, because treeSize is a power of two above the ship limit. The update climbs from leaf to root and recomputes one parent per level. The search tests the left child at each level and returns the leaf index minus treeSize. Each call costs about 17 steps.

```nim
var tree: array[2 * treeSize, int]
var remainingCapacity: array[maxShips + 4, int]
var shipCount = 0
var capacity = 0

proc updateCapacity(i: int, value: int) =
  var node = treeSize + i
  tree[node] = value
  while node > 1:
    node = node shr 1
    let leftChild = node shl 1
    let rightChild = leftChild or 1
    let leftValue = tree[leftChild]
    let rightValue = tree[rightChild]
    tree[node] = if leftValue >= rightValue: leftValue else: rightValue

proc leftmostFitting(threshold: int): int =
  if tree[1] < threshold:
    return -1
  var node = 1
  while node < treeSize:
    let leftChild = node shl 1
    if tree[leftChild] >= threshold:
      node = leftChild
    else:
      node = leftChild or 1
  return node - treeSize
```

The outer loop runs while the block still has containers. The first branch opens new ships that each hold capacity div blockVolume containers. The inner loop fills ships in index order and stops when the block is empty. One update per visited ship keeps the tree current.

```nim
proc placeContainers(repeatCount: int, blockVolume: int) =
  var remaining = repeatCount
  while remaining > 0:
    var i = leftmostFitting(blockVolume)
    if i < 0:
      let perShip = capacity div blockVolume
      while remaining > 0:
        let take = if remaining < perShip: remaining else: perShip
        remainingCapacity[shipCount] = capacity - take * blockVolume
        updateCapacity(shipCount, remainingCapacity[shipCount])
        shipCount += 1
        remaining -= take
      return
    while remaining > 0 and i < shipCount:
      let fitCount = remainingCapacity[i] div blockVolume
      if fitCount == 0:
        i += 1
      else:
        let take = if remaining < fitCount: remaining else: fitCount
        remainingCapacity[i] -= take * blockVolume
        updateCapacity(i, remainingCapacity[i])
        remaining -= take
        if remaining > 0:
          i += 1
```

The case loop reads the capacity and the container count, then clears the tree and the ship count. Each token either starts a block or gives one volume. The waste sums the free space of the used ships, and one final write flushes the buffer.

```nim
let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  capacity = nextInt(inputData, i)
  let containerCount = nextInt(inputData, i)
  for k in 0..<tree.len:
    tree[k] = 0
  shipCount = 0
  var processed = 0
  while processed < containerCount:
    skipSpaces(inputData, i)
    if i < inputData.len and (inputData[i] == 'b' or inputData[i] == 'B'):
      i += 1
      let repeatCount = nextInt(inputData, i)
      let blockVolume = nextInt(inputData, i)
      placeContainers(repeatCount, blockVolume)
      processed += repeatCount
    else:
      let singleVolume = nextInt(inputData, i)
      placeContainers(1, singleVolume)
      processed += 1
  var totalWaste: int64 = 0
  for k in 0..<shipCount:
    totalWaste += int64(remainingCapacity[k])
  appendOutput($shipCount & " " & $totalWaste)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

## Complexity

Reading costs one pass over the input buffer. Each block costs one tree descent, and each visited ship costs one tree update that climbs 17 levels. Clearing the tree costs 2 times treeSize operations per case.

Total time is O(input tokens plus visited ships times log 100000). Space is O(100000 plus treeSize). The naive form scans every ship for every container and costs O(n times s) per case.

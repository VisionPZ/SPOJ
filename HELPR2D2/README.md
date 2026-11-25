# HELPR2D2 — Help R2-D2! (SPOJ)
<https://www.spoj.com/problems/HELPR2D2/>

## Problem

The input gives a ship capacity and a sequence of container volumes.
Placing each container into the lowest-indexed ship with enough room, compute the ships used and the total unused volume.

Each case starts with a ship capacity K, a container count n, then n entries. An entry is one volume, or the letter `b` with a repeat count r and a volume v, meaning r containers of volume v. Print the ship count and the total unused volume on one line.

The judge limits are:

| Item | Value |
| --- | --- |
| Test cases T | at most 10 |
| Ship capacity K | at most 1000 |
| Containers per case n | 1 to 1000000 |
| Starships used | at most 100000 |
| Ship changes | at most 100000 |
| Time limit | 7 s |
| Memory limit | 1536 MB |

The container and ship counts drive the design, while the answer holds two numbers.

The sample input reads:

```text
2
100
3
50
25
70
100
4
50
b 2 40
20
```

The sample output reads:

```text
2 55
2 50
```

## Idea

Keep the ships in a row and always fill the leftmost one with room, like choosing the nearest open starship. A segment tree (a binary tree storing the maximum free space of each range) finds that ship in about 17 steps. Inside a block the volume stays fixed. A ship that no longer fits stays unusable, so the loader walks ships in index order. Each visit costs one tree update of 17 steps. Scanning every ship for every container would cost O(n times s). Takeaway: use a tree for the search, then sweep ships once per block.

## Why It Works

1. The greedy rule always takes the lowest numbered ship with enough free space.
2. Free space only decreases, so a ship below the block volume stays unusable for the rest of that block.
3. The tree stores the maximum free space in each range of ship indices.
4. `leftmostFitting` descends to the lowest leaf whose free space reaches the threshold, or returns -1 when the root maximum is smaller.
5. `updateCapacity` writes one leaf and recomputes each parent as the larger of its two children.
6. The `fitCount` value divides remaining capacity by block volume. `take` is the smaller of that value and the remaining count.
7. Opening a ship stores `capacity - take * blockVolume` as its free space.

The table names the terms.

| Term | Meaning |
| --- | --- |
| `treeSize` | 2^17, one leaf per possible ship |
| `remainingCapacity` | free space left in one ship |
| `leftmostFitting` | lowest ship index with enough free space |
| `fitCount` | containers that fit in one ship during a block |

These four terms guide each block.

A script replayed the first sample case.

| Container | Volume | Action | Ship | Remaining capacities |
| --- | --- | --- | --- | --- |
| 1 | 50 | open ship | S0 | 50 |
| 2 | 25 | reuse | S0 | 25 |
| 3 | 70 | open ship | S1 | 25, 30 |

The waste is 25 + 30 = 55, so the program prints `2 55`.

## Code

**Input and output helpers.** The code reads once, scans integers by hand, and buffers answers.

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

`treeSize` is a power of two above the ship limit. `skipSpaces` lets the driver test for the block letter before parsing numbers. The digit loop visits each input byte once. The output helper writes only after the buffer reaches 256 KiB.

**Tree search and update.** One leaf per ship holds its free space.

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

The update climbs from leaf to root and recomputes one parent per level. The search tests the left child at each level, so it always reaches the lowest fitting leaf. Each call costs about 17 steps. Returning `node - treeSize` converts a leaf index into a ship index.

**Placement.** The outer loop repeats while a block still has containers.

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

The first branch opens new ships that each hold `capacity div blockVolume` containers. The inner loop fills ships in index order and stops when the block is empty. One update per visited ship keeps the tree current. A ship that cannot fit is skipped for the rest of the block.

**Driver.** Each case reads its capacity, container count, and entries, then sums the waste.

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

The tree is cleared once per case, and the ship count restarts at zero. A `b` entry adds `repeatCount` processed containers at once. The waste sums the free space of used ships as a 64-bit value. The final write flushes the remaining output bytes.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| Read one case | O(input bytes) | one buffer |
| Clear tree | O(2 * treeSize) | O(treeSize) |
| One tree descent or update | O(log 100000) | O(1) |

The tree dominates each container visit.

Each visited ship costs one 17-level climb.

| Measure | Bound |
| --- | --- |
| Per case | O(input tokens + visited ships * log 100000) |
| Space | O(100000 + treeSize) |
| Waste sum | O(ships used) |

The naive form scans every ship for every container and costs O(n times s) per case.

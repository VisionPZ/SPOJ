# EXPEDI — Expedition (SPOJ)

<https://www.spoj.com/problems/EXPEDI/>

## Problem

A truck starts `L` units from a town with `P` units of fuel and burns one unit per unit traveled. Given `N` fuel stops at distances `d` from the town, each with a fuel amount, find the fewest stops needed to reach the town.

Input: an integer `t`, then `t` cases. Each case gives `N`, then `N` lines of `d` and fuel, then one line with `L` and `P`. Output: one integer per case, the minimum stop count, or -1 when the town is unreachable. The distance from the truck to a stop is `L − d`.

The bounds from the statement and judge:

| Item | Bound |
|---|---|
| Test cases `t` | not bounded in the statement |
| Stops `N` | 1 ≤ N ≤ 10000 |
| Distance from town `d` | 0 ≤ d ≤ 1000000 |
| Fuel at a stop | 1..100 |
| Start distance `L` | 1 ≤ L ≤ 1000000 |
| Starting fuel `P` | 1 ≤ P ≤ 1000000 |
| Judge limit | 2307 ms, 1536 MB |

The stop count `N`, not the distance range, drives the work and the memory.

The sample case:

```
1
4
4 4
5 2
11 5
15 10
25 10
```

```
2
```

## Idea

Keep the largest fuel amount passed so far in reserve, and spend it when the tank cannot reach the next stop. Think of holding the biggest bill in your wallet until a purchase needs it.

The program uses a forward greedy with a max heap, a structure that returns its largest value first. Sorting puts the stops in travel order, so the truck considers each stop once. A push or a pop costs O(log N), and the sort costs O(N log N) per case.

Trying every subset of stops costs exponential time. Scanning all earlier stops for the next fuel costs O(N²) per stop. The greedy passes each stop once and spends only when short.

## Why It Works

Four facts support the greedy.

1. A stop helps only after the truck reaches it, so its fuel enters the heap at that moment.
2. When fuel falls short, spending the largest available amount leaves the most fuel for the same spent stop.
3. Waiting until fuel is short costs nothing, because the tank has no capacity limit.
4. An empty heap and a stop beyond the fuel prove that no route reaches the town.

The program tracks these values:

| Term | Meaning |
|---|---|
| `L − d` | distance from the truck to a stop |
| `travelDistance` | target stop distance minus the last stop distance |
| `currentFuel` | fuel left after the last paid stop |
| `largestFuel` | largest fuel among passed stops, from `popMaxFuel` |
| `stopsUsed` | count of `popMaxFuel` calls |

Every term stays an integer, so this problem needs no rounding or guard step.

A script traces the sample with visible numbers:

```
town L = 25, starting fuel P = 10
sorted stops (distance from start, fuel): (10, 10) (14, 5) (20, 2) (21, 4)
        step target  gap before refuel after used
    (10, 10)     10   10     10      -     0    0
     (14, 5)     14    4      0    +10     6    1
     (20, 2)     20    6      6      -     0    1
     (21, 4)     21    1      0     +5     4    2
        town     25    4      4      -     0    2
```

The two spends at distances 14 and 21 give the sample answer 2.

## Code

**Constants and flat buffers.** These values and arrays live for the whole run.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxStopsPerCase = 10000

var stopDistances = newSeq[int](maxStopsPerCase + 1)
var stopFuels = newSeq[int](maxStopsPerCase + 1)
var heapFuels = newSeq[int](maxStopsPerCase + 1)
var heapSize = 0
```

The arrays hold at most 10000 entries and are reused by every case. The parent index uses `(childIndex - 1) div 2` for the heap. Allocating once keeps the per-case loop free of new sequences.

**Largest-fuel heap.** These two procedures maintain the reserve of passed fuels.

```nim
proc pushFuel(fuelAmount: int) =
  heapFuels[heapSize] = fuelAmount
  var childIndex = heapSize
  heapSize += 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heapFuels[parentIndex] >= heapFuels[childIndex]: break
    swap heapFuels[parentIndex], heapFuels[childIndex]
    childIndex = parentIndex

proc popMaxFuel(): int =
  let largestFuel = heapFuels[0]
  heapSize -= 1
  if heapSize > 0:
    heapFuels[0] = heapFuels[heapSize]
    var parentIndex = 0
    while true:
      let leftChild = 2 * parentIndex + 1
      if leftChild >= heapSize: break
      let rightChild = leftChild + 1
      var largerChild = leftChild
      if rightChild < heapSize and heapFuels[rightChild] > heapFuels[leftChild]:
        largerChild = rightChild
      if heapFuels[parentIndex] >= heapFuels[largerChild]: break
      swap heapFuels[parentIndex], heapFuels[largerChild]
      parentIndex = largerChild
  return largestFuel
```

Each push climbs at most log N levels, and each pop descends at most log N levels. The root at index 0 always holds the largest fuel. A pop moves the last fuel to the root before sifting down.

**Stop order.** These procedures place stops in travel order.

```nim
proc quickSortStops(lowIndex, highIndex: int) =
  if lowIndex >= highIndex: return
  let pivotDistance = stopDistances[(lowIndex + highIndex) div 2]
  var leftIndex = lowIndex
  var rightIndex = highIndex
  while leftIndex <= rightIndex:
    while stopDistances[leftIndex] < pivotDistance: leftIndex += 1
    while stopDistances[rightIndex] > pivotDistance: rightIndex -= 1
    if leftIndex <= rightIndex:
      swap stopDistances[leftIndex], stopDistances[rightIndex]
      swap stopFuels[leftIndex], stopFuels[rightIndex]
      leftIndex += 1
      rightIndex -= 1
  if lowIndex < rightIndex: quickSortStops(lowIndex, rightIndex)
  if leftIndex < highIndex: quickSortStops(leftIndex, highIndex)

proc sortStops(stopTotal: int) =
  if stopTotal > 1: quickSortStops(0, stopTotal - 1)
```

The loop swaps distance and fuel together, so each stop stays intact. The middle pivot keeps recursion depth near log N. The cost is O(N log N) comparisons per case.

**Digit scanner and output block.** Input is scanned once, and output waits for a full block.

```nim
proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips separators and builds values one digit at a time. `firstDigitValue` turns a digit byte into a digit value. The buffer flushes at `flushBlockBytes` and reuses its storage with `setLen 0`.

**Case driver.** This loop reads every case, sweeps its stops, and emits one answer.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
for _ in 0..<caseCount:
  let stopCount = nextInt(inputData, scanPos)
  for stopIndex in 0..<stopCount:
    stopDistances[stopIndex] = nextInt(inputData, scanPos)
    stopFuels[stopIndex] = nextInt(inputData, scanPos)
  let townDistance = nextInt(inputData, scanPos)
  let startingFuel = nextInt(inputData, scanPos)
  var keptCount = 0
  for stopIndex in 0..<stopCount:
    let distanceFromTown = stopDistances[stopIndex]
    if distanceFromTown <= townDistance:
      stopDistances[keptCount] = townDistance - distanceFromTown
      stopFuels[keptCount] = stopFuels[stopIndex]
      keptCount += 1
  sortStops(keptCount)
  heapSize = 0
  var currentFuel = startingFuel
  var currentPosition = 0
  var stopsUsed = 0
  var reachable = true
  for stopIndex in 0..<keptCount:
    let targetPosition = stopDistances[stopIndex]
    let travelDistance = targetPosition - currentPosition
    if travelDistance > currentFuel:
      while currentFuel < travelDistance and heapSize > 0:
        currentFuel += popMaxFuel()
        stopsUsed += 1
      if currentFuel < travelDistance:
        reachable = false
        break
    currentFuel -= travelDistance
    currentPosition = targetPosition
    pushFuel(stopFuels[stopIndex])
  if reachable:
    let remainingDistance = townDistance - currentPosition
    if remainingDistance > currentFuel:
      while currentFuel < remainingDistance and heapSize > 0:
        currentFuel += popMaxFuel()
        stopsUsed += 1
    if currentFuel >= remainingDistance:
      appendOutput($stopsUsed)
    else:
      reachable = false
  if not reachable: appendOutput("-1")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Stops beyond the truck are dropped before sorting. The sweep adds each passed fuel to the heap and spends the largest one only when `travelDistance` exceeds `currentFuel`. The last write flushes the tail after every case.

## Complexity

The cost per case splits into four phases:

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Sort | O(N log N) comparisons | three flat arrays |
| Sweep with heap | O(N log N) pushes and pops | heap array of N fuels |
| Output | one write per 256 KiB block | block buffer |

Sorting and the heap dominate; input and output stay linear in the bytes they handle.

The overall asymptotic bounds:

| Measure | Big O |
|---|---|
| Time | O(N log N) per case |
| Space | O(N) for distances, fuels and the heap |

The distance bound 1000000 never appears in memory. Testing every subset of stops costs O(2^N) time, while this sweep costs O(N log N) per case.

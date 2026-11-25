# PANIC — Panic in the Plazas (SPOJ)
<https://www.spoj.com/problems/PANIC/>

## Problem

Bags of fake bombs burst at several plazas at noon. Panic then runs along the streets, and crowds choose their escape route to survive as long as possible.

You sit at one plaza that day. Find every plaza that maximizes your survival time, and print them in increasing order. A plaza that panic never reaches also counts as a safe choice.

Input: the first integer is t, the number of cases. Each case gives n plazas, m streets, and k bag plazas. Each street line holds u, v, the time u → v, and the time v → u. The last line lists the k bag plazas. Output: one line per case with the increasing plaza numbers that give the longest survival.

These are the bounds and the judge limits:

| Item | Bound |
| --- | --- |
| Test cases t | at most 500 |
| Plazas n | 1 to 50000 |
| Streets m | 0 to 250000 |
| Bag plazas k | 0 to n |
| Street crossing time | 1 to 1000 |
| Time limit | 2267 ms |
| Memory limit | 1536 MB |

The sample has a connected case and a case with one bag and no street:

```
2

4 5 2
1 2 10 10
2 4 30 30
3 2 10 10
4 3 50 5
3 1 5  50
1 2

2 0 1
2
```

```
2 3 4
1
```

In the first case the longest survival is 22.5 time units.

## Idea

Spread the panic first, then work out the best escape from every plaza. Imagine a fire starting at several cafés at once, with people running down every street except the one the smoke came from.

The program runs Dijkstra (a shortest-path search that always expands the closest plaza) from all bag plazas at once. The distance d[v] is the moment panic reaches plaza v. A shortest-path tree records the street panic came from; people cannot use that street to escape.

For each plaza, the program checks every other street. It keeps the best survival time as a fraction, with a numerator and a denominator. Plazas are processed in decreasing distance, so any plaza further out already has its answer ready.

Dijkstra costs O((n + m) log m), the distance sort costs O(n log n), and the escape scan costs O(n + m). Checking every possible escape path by brute force has no practical bound.

Takeaway: one shortest-path tree turns a maze of escape choices into a single scan per plaza.

## Why It Works

Five facts prove the computation.

1. Multi-source Dijkstra gives d[v], the earliest time panic reaches v. Starting with all bag plazas at distance zero seeds every source at once.
2. The parent arc of v is the street panic used to arrive. People exiting v skip that arc and consider all others.
3. If an escape reaches neighbor w exactly when panic reaches w, the survival time equals the survival time at w.
4. If two crowds meet inside a street, the meeting time is the rational formula below. Cross multiplication compares two such times exactly.
5. Processing plazas from large d to small d makes every further plaza's survival known first. Unreachable plazas never see panic and are printed directly.

These are the terms used in the escape scan:

| Term | Meaning |
| --- | --- |
| `minDist[v]` | time d[v] when panic reaches plaza v |
| `arcWeight[arc]` | crossing time of that directed street |
| parent arc | street through which panic first reached the plaza |
| `arrive` | d[u] + weight(u → v), the escape arrival time |
| meeting time | (d[u]·w(v→u) + d[v]·w(u→v) + w(u→v)·w(v→u)) / (w(u→v) + w(v→u)) |
| `survivalNum`, `survivalDen` | numerator and denominator of a survival time |

A script traces the first sample case with fractions kept exact:

```
plaza 4: dist 15, best 45/2 = 22.5
plaza 3: dist 10, best 45/2 = 22.5
plaza 2: dist 0,  best 45/2 = 22.5
plaza 1: dist 0,  best 150/11 = 13.636...
max plazas: 2 3 4
```

The key step is plaza 4 escaping along street 4-2. The meeting formula gives (15·30 + 0·30 + 30·30) / 60 = 1350 / 60 = 45/2. Rounding never enters the comparison, because the code compares products of numerators and denominators.

## Code

**Setup and scanner.** The program reads the whole stream in large chunks.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const readChunkBytes = 1 shl 20
const unreachable = 1 shl 60

{.push checks: off.}
{.passC: "-O3".}

proc nextInt(data: string, pos: var int): int {.inline.} =
  var curPos = pos
  let dataLen = data.len
  while curPos < dataLen and (data[curPos] < '0' or data[curPos] > '9'):
    curPos += 1
  var value = 0
  while curPos < dataLen and data[curPos] >= '0' and data[curPos] <= '9':
    value = value * 10 + int(data[curPos]) - firstDigitValue
    curPos += 1
  pos = curPos
  return value

var inputData = ""
var readChunk = newString(readChunkBytes)
while true:
  let bytesRead = stdin.readBuffer(readChunk[0].addr, readChunk.len)
  if bytesRead == 0:
    break
  let startPos = inputData.len
  inputData.setLen(startPos + bytesRead)
  copyMem(inputData[startPos].addr, readChunk[0].addr, bytesRead)
```

The loop appends fixed-size chunks into one buffer. `copyMem` avoids per-byte work. The cost is one pass over the input bytes.

**Output.** Answers gather in one buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush happens every `flushBlockBytes` bytes. No write occurs while processing a case. The cost is one pass over the answer text.

**Pre-scan.** The program measures the largest case before allocating arrays.

```nim
var scanAt = 0
let caseCount = nextInt(inputData, scanAt)
var scanProbe = scanAt
var largestNodeCount = 0
var largestStreetCount = 0
for caseIndex in 0..<caseCount:
  let nodeCount = nextInt(inputData, scanProbe)
  let streetCount = nextInt(inputData, scanProbe)
  let bagCount = nextInt(inputData, scanProbe)
  if nodeCount > largestNodeCount:
    largestNodeCount = nodeCount
  if streetCount > largestStreetCount:
    largestStreetCount = streetCount
  for streetIndex in 0..<streetCount:
    discard nextInt(inputData, scanProbe)
    discard nextInt(inputData, scanProbe)
    discard nextInt(inputData, scanProbe)
    discard nextInt(inputData, scanProbe)
  for bagIndex in 0..<bagCount:
    discard nextInt(inputData, scanProbe)
```

A separate cursor, `scanProbe`, leaves `scanAt` untouched for the real pass. Only house and street counts are recorded. The cost is one extra scan of the input.

**Buffers.** Arrays are sized once from the pre-scan maxima.

```nim
let maxNodeCount = largestNodeCount + 2
let maxArcCount = 2 * largestStreetCount + 5
let maxStreetCount = largestStreetCount + 2

var arcStart = newSeq[int](maxNodeCount + 2)
var arcCursor = newSeq[int](maxNodeCount + 2)
var arcCount = newSeq[int](maxNodeCount + 2)
var arcTo = newSeq[int](maxArcCount)
var arcWeight = newSeq[int](maxArcCount)
var arcReverse = newSeq[int](maxArcCount)
var streetFrom = newSeq[int](maxStreetCount)
var streetTarget = newSeq[int](maxStreetCount)
var streetForward = newSeq[int](maxStreetCount)
var streetBackward = newSeq[int](maxStreetCount)
var minDist = newSeq[int](maxNodeCount + 2)
var isBagNode = newSeq[bool](maxNodeCount + 2)
var isParentArc = newSeq[bool](maxArcCount)
var heapNode = newSeq[int](maxArcCount)
var heapDist = newSeq[int](maxArcCount)
var ordered = newSeq[int](maxNodeCount + 2)
var survivalNum = newSeq[int64](maxNodeCount + 2)
var survivalDen = newSeq[int64](maxNodeCount + 2)
var heapSize = 0
var poppedDist = 0
```

Each street creates two arcs, so `maxArcCount` is twice the street count plus slack. Reusing buffers avoids per-case allocation. Space is O(n + m).

**Heap.** A binary heap holds the Dijkstra frontier.

```nim
proc heapPush(nodeIndex, nodeDist: int) {.inline.} =
  var idx = heapSize
  heapSize += 1
  while idx > 0:
    let parentIndex = (idx - 1) div 2
    if heapDist[parentIndex] <= nodeDist:
      break
    heapNode[idx] = heapNode[parentIndex]
    heapDist[idx] = heapDist[parentIndex]
    idx = parentIndex
  heapNode[idx] = nodeIndex
  heapDist[idx] = nodeDist

proc heapPop(): int {.inline.} =
  result = heapNode[0]
  poppedDist = heapDist[0]
  heapSize -= 1
  if heapSize == 0:
    return
  let lastNode = heapNode[heapSize]
  let lastDist = heapDist[heapSize]
  var idx = 0
  while true:
    let leftChild = 2 * idx + 1
    if leftChild >= heapSize:
      break
    let rightChild = leftChild + 1
    var child = leftChild
    if rightChild < heapSize and heapDist[rightChild] < heapDist[leftChild]:
      child = rightChild
    if heapDist[child] >= lastDist:
      break
    heapNode[idx] = heapNode[child]
    heapDist[idx] = heapDist[child]
    idx = child
  heapNode[idx] = lastNode
  heapDist[idx] = lastDist
```

`heapPop` also stores the popped distance in `poppedDist`. The caller uses it to skip stale entries. Each push or pop costs O(log m).

**Sort.** The plazas are ordered by distance before the escape scan.

```nim
proc siftDown(values: var seq[int], rootIndex, endIndex: int) {.inline.} =
  var root = rootIndex
  while true:
    var child = 2 * root + 1
    if child > endIndex:
      break
    if child < endIndex and minDist[values[child]] > minDist[values[child + 1]]:
      child += 1
    if minDist[values[root]] <= minDist[values[child]]:
      break
    swap(values[root], values[child])
    root = child

proc sortByDistance(values: var seq[int], count: int) =
  var startIndex = count div 2 - 1
  while startIndex >= 0:
    siftDown(values, startIndex, count - 1)
    startIndex -= 1
  var finish = count - 1
  while finish > 0:
    swap(values[0], values[finish])
    siftDown(values, 0, finish - 1)
    finish -= 1
```

The heap uses the smaller child, so extraction produces decreasing distances. Farther plazas are therefore processed first. Sorting costs O(n log n).

**Case processing.** Each case builds the graph, spreads panic, and scores escapes.

```nim
for caseIndex in 0..<caseCount:
  let nodeCount = nextInt(inputData, scanAt)
  let streetCount = nextInt(inputData, scanAt)
  let bagCount = nextInt(inputData, scanAt)
  let arcTotal = 2 * streetCount

  for nodeIndex in 1..nodeCount:
    arcCount[nodeIndex] = 0
    minDist[nodeIndex] = unreachable
    isBagNode[nodeIndex] = false

  for streetIndex in 0..<streetCount:
    let fromNode = nextInt(inputData, scanAt)
    let toNode = nextInt(inputData, scanAt)
    streetFrom[streetIndex] = fromNode
    streetTarget[streetIndex] = toNode
    streetForward[streetIndex] = nextInt(inputData, scanAt)
    streetBackward[streetIndex] = nextInt(inputData, scanAt)
    arcCount[fromNode] += 1
    arcCount[toNode] += 1

  arcStart[1] = 0
  for nodeIndex in 1..nodeCount:
    arcStart[nodeIndex + 1] = arcStart[nodeIndex] + arcCount[nodeIndex]
    arcCursor[nodeIndex] = arcStart[nodeIndex]

  for streetIndex in 0..<streetCount:
    let fromNode = streetFrom[streetIndex]
    let toNode = streetTarget[streetIndex]
    let forwardArc = arcCursor[fromNode]
    arcCursor[fromNode] += 1
    arcTo[forwardArc] = toNode
    arcWeight[forwardArc] = streetForward[streetIndex]
    let backwardArc = arcCursor[toNode]
    arcCursor[toNode] += 1
    arcTo[backwardArc] = fromNode
    arcWeight[backwardArc] = streetBackward[streetIndex]
    arcReverse[forwardArc] = backwardArc
    arcReverse[backwardArc] = forwardArc

  for bagIndex in 0..<bagCount:
    let bagNode = nextInt(inputData, scanAt)
    isBagNode[bagNode] = true
    minDist[bagNode] = 0

  heapSize = 0
  for nodeIndex in 1..nodeCount:
    if isBagNode[nodeIndex]:
      heapPush(nodeIndex, 0)

  while heapSize > 0:
    let nodeIndex = heapPop()
    if poppedDist != minDist[nodeIndex]:
      continue
    let baseDist = minDist[nodeIndex]
    for arcIndex in arcStart[nodeIndex]..<arcStart[nodeIndex + 1]:
      let nextDist = baseDist + arcWeight[arcIndex]
      let target = arcTo[arcIndex]
      if nextDist < minDist[target]:
        minDist[target] = nextDist
        heapPush(target, nextDist)

  for arcIndex in 0..<arcTotal:
    isParentArc[arcIndex] = false
  for nodeIndex in 1..nodeCount:
    if isBagNode[nodeIndex]:
      continue
    for arcIndex in arcStart[nodeIndex]..<arcStart[nodeIndex + 1]:
      if minDist[arcTo[arcIndex]] + arcWeight[arcReverse[arcIndex]] == minDist[nodeIndex]:
        isParentArc[arcIndex] = true

  for nodeIndex in 1..nodeCount:
    ordered[nodeIndex - 1] = nodeIndex
  sortByDistance(ordered, nodeCount)

  for sliceIndex in 0..<nodeCount:
    let nodeIndex = ordered[sliceIndex]
    if minDist[nodeIndex] == unreachable:
      continue
    var bestNum: int64 = 0
    var bestDen: int64 = 1
    var haveBest = false
    for arcIndex in arcStart[nodeIndex]..<arcStart[nodeIndex + 1]:
      if not isParentArc[arcIndex]:
        let target = arcTo[arcIndex]
        let forwardWeight = arcWeight[arcIndex]
        let arrive = minDist[nodeIndex] + forwardWeight
        var valueNum: int64 = 0
        var valueDen: int64 = 1
        if arrive == minDist[target]:
          valueNum = survivalNum[target]
          valueDen = survivalDen[target]
        elif minDist[target] < arrive and minDist[nodeIndex] < minDist[target] + arcWeight[arcReverse[arcIndex]]:
          valueNum = int64(minDist[nodeIndex]) * arcWeight[arcReverse[arcIndex]] +
                     int64(minDist[target]) * forwardWeight +
                     int64(forwardWeight) * arcWeight[arcReverse[arcIndex]]
          valueDen = int64(forwardWeight + arcWeight[arcReverse[arcIndex]])
        else:
          valueNum = int64(arrive)
          valueDen = 1
        if not haveBest or valueNum * bestDen > bestNum * valueDen:
          bestNum = valueNum
          bestDen = valueDen
          haveBest = true
    if not haveBest:
      bestNum = int64(minDist[nodeIndex])
      bestDen = 1
    survivalNum[nodeIndex] = bestNum
    survivalDen[nodeIndex] = bestDen

  var hasHidden = false
  for nodeIndex in 1..nodeCount:
    if minDist[nodeIndex] == unreachable:
      hasHidden = true
      break

  if hasHidden:
    var firstWritten = true
    for nodeIndex in 1..nodeCount:
      if minDist[nodeIndex] == unreachable:
        if not firstWritten:
          appendOutput(" ")
        appendOutput($(nodeIndex))
        firstWritten = false
    appendOutput("\n")
    continue

  var maxNum: int64 = survivalNum[1]
  var maxDen: int64 = survivalDen[1]
  for nodeIndex in 2..nodeCount:
    if survivalNum[nodeIndex] * maxDen > maxNum * survivalDen[nodeIndex]:
      maxNum = survivalNum[nodeIndex]
      maxDen = survivalDen[nodeIndex]

  var firstWritten = true
  for nodeIndex in 1..nodeCount:
    if survivalNum[nodeIndex] * maxDen == maxNum * survivalDen[nodeIndex]:
      if not firstWritten:
        appendOutput(" ")
      appendOutput($(nodeIndex))
      firstWritten = false
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

`arcStart` gives each plaza a contiguous arc slice. Dijkstra skips stale heap entries with the `poppedDist` check. The escape loop compares fractions by cross products, which avoids rounding errors. Printing all unreachable plazas handles the infinite-survival case.

## Complexity

Graph setup, shortest paths, and the escape scan share the work.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(total tokens) | O(input size) |
| Pre-scan and allocation | O(total tokens) | O(n + m) |
| Graph build per case | O(n + m) | O(n + m) |
| Multi-source Dijkstra | O((n + m) log m) | O(n + m) |
| Distance sort | O(n log n) | O(n) |
| Escape scan and output | O(n + m) | O(n) |

Dijkstra and the sort dominate, with O((n + m) log m) time per case.

| Measure | Big O |
| --- | --- |
| Time per case | O((n + m) log m) |
| Total time | O(sum over cases of (n + m) log m) |
| Working space | O(n + m) |

Enumerating escape paths separately for every plaza would take far longer than one tree plus one scan.

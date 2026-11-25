# CAVE — Cave Exploration (SPOJ)
<https://www.spoj.com/problems/CAVE/>

## Problem

An explorer walks cave corridors with a fixed rule: turn left if possible, else go straight, else turn right, else turn back. He stops on reaching the entry point again. Count the corridors he never touched.

Input starts with a map count T. Each map gives a corridor count N, then N corridor lines. Each line starts with V or H and holds three coordinates: one fixed line coordinate and two bounds. The last line gives the entry x, entry y, and heading N, E, S, or W. Output the unvisited corridor count per map.

The map limits are these:

| Quantity | Bound |
| --- | --- |
| Maps | 20 |
| Corridors per map | 1000, at most 500 each direction |
| Coordinate magnitude | 32,767 |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

The corridor count stays small, so per-map setup costs little.

The sample input and output:

```
2
6
H 0 6 0
H 2 1 6
V 1 0 4
V 5 3 0
V 3 0 2
H 1 2 4
6 0 W
1
V 0 -5 5
0 0 S
```

```
1
0
```

The first map leaves one corridor unvisited; the second visits its only corridor.

## Idea

Split every corridor at crossings and endpoints, then walk from node to node. The turn rule follows one face boundary of the corridor graph, so each directed piece leads to exactly one successor. Think of tracing a maze with your left hand on the wall: you return to the start after walking one connected boundary.

Each step finds the next node by binary search, O(log 500), and building the node lists costs O(V times H) per map. Stepping unit by unit and rechecking geometry at every point would be slower and harder to keep exact.

Takeaway: turn corridors into node lists, then follow the successor rule.

## Why It Works

1. No two vertical corridors share a point, and no two horizontal corridors do either.
2. At a node, at most one vertical and one horizontal corridor meet, so at most four exits exist.
3. The successor order left, straight, right, back permutes the directed pieces, so the walk must return to its start.
4. Standing on a crossing touches both corridors, so the program marks both as visited.
5. A vertical corridor's node list holds its two endpoints and every horizontal line that crosses it.
6. `findIndex` binary searches that sorted list, and a north move steps to node index k + 1, a south move to k - 1.

The walk uses these terms.

| Term | Meaning |
| --- | --- |
| `vNodes[k]` | sorted y values along vertical corridor k |
| `hNodes[k]` | sorted x values along horizontal corridor k |
| `vCrossH`, `hCrossV` | crossing corridor at each node, or -1 |
| `canGo` | four flags for exits in that direction |
| `wasVisited` | marks corridors already touched |

A turn onto another corridor finds the shared coordinate, then steps one node past it.

A script walked the first sample map:

| Quantity | Value |
| --- | --- |
| Sample corridors | 6 |
| Visited ids | 0, 1, 2, 3, 4 |
| Unvisited ids | 5 |
| Answer | 1 |

Only the horizontal corridor at input index 5 stays untouched, so the answer is 1.

## Code

**Constants, scanners, and helpers.**
```nim
import std/algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const northDir = 0
const eastDir = 1
const southDir = 2
const westDir = 3
const verticalKind = 0
const horizontalKind = 1

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc isDashStart(data: string, pos: int): bool =
  if pos >= data.len: return false
  if data[pos] == '-': return true
  if ord(data[pos]) == 0xE2 and pos + 2 < data.len:
    let second = ord(data[pos + 1])
    let third = ord(data[pos + 2])
    if (second == 0x88 and third == 0x92) or
       (second == 0x80 and (third == 0x90 or third == 0x91 or third == 0x92 or third == 0x93 or third == 0x94 or third == 0x95 or third == 0x96 or third == 0x97)):
      return true
  return false

proc skipSeparators(data: string, pos: var int) =
  while pos < data.len and not isDashStart(data, pos) and (data[pos] < '0' or data[pos] > '9'):
    pos += 1

proc nextInt(data: string, pos: var int): int =
  skipSeparators(data, pos)
  var sign = 1
  if isDashStart(data, pos):
    sign = -1
    if ord(data[pos]) == 0xE2:
      pos += 3
    else:
      pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value * sign

proc nextUpper(data: string, pos: var int): char =
  while pos < data.len and (data[pos] < 'A' or data[pos] > 'Z'):
    pos += 1
  let letter = data[pos]
  pos += 1
  return letter

proc cmpInt(firstValue, secondValue: int): int =
  if firstValue < secondValue: return -1
  if firstValue > secondValue: return 1
  return 0

proc findIndex(values: seq[int], target: int): int =
  var lo = 0
  var hi = values.len - 1
  while lo <= hi:
    let mid = (lo + hi) div 2
    if values[mid] < target:
      lo = mid + 1
    elif values[mid] > target:
      hi = mid - 1
    else:
      return mid
  return -1

proc sortedUnique(original: seq[int]): seq[int] =
  var sortedVals = original
  sortedVals.sort(cmpInt)
  var j = 0
  for i in 0..<sortedVals.len:
    if i == 0 or sortedVals[i] != sortedVals[i - 1]:
      sortedVals[j] = sortedVals[i]
      j += 1
  sortedVals.setLen(j)
  return sortedVals

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```
`isDashStart` recognizes both ASCII and Unicode minus signs. `nextInt` and `nextUpper` read coordinates and headings. `findIndex` and `sortedUnique` maintain the node lists. `appendOutput` flushes in blocks.

**Map input and start point.**
```nim
let caseCount = nextInt(inputData, scanPos)
for caseIdx in 0..<caseCount:
  let corridorCount = nextInt(inputData, scanPos)
  var vX = newSeq[int](corridorCount)
  var vLo = newSeq[int](corridorCount)
  var vHi = newSeq[int](corridorCount)
  var vGlobal = newSeq[int](corridorCount)
  var hY = newSeq[int](corridorCount)
  var hLo = newSeq[int](corridorCount)
  var hHi = newSeq[int](corridorCount)
  var hGlobal = newSeq[int](corridorCount)
  var vCount = 0
  var hCount = 0
  for i in 0..<corridorCount:
    let corridorKind = nextUpper(inputData, scanPos)
    let firstNum = nextInt(inputData, scanPos)
    let secondNum = nextInt(inputData, scanPos)
    let thirdNum = nextInt(inputData, scanPos)
    if corridorKind == 'V':
      vX[vCount] = firstNum
      if secondNum < thirdNum:
        vLo[vCount] = secondNum
        vHi[vCount] = thirdNum
      else:
        vLo[vCount] = thirdNum
        vHi[vCount] = secondNum
      vGlobal[vCount] = i
      vCount += 1
    else:
      hY[hCount] = firstNum
      if secondNum < thirdNum:
        hLo[hCount] = secondNum
        hHi[hCount] = thirdNum
      else:
        hLo[hCount] = thirdNum
        hHi[hCount] = secondNum
      hGlobal[hCount] = i
      hCount += 1
  vX.setLen(vCount)
  vLo.setLen(vCount)
  vHi.setLen(vCount)
  vGlobal.setLen(vCount)
  hY.setLen(hCount)
  hLo.setLen(hCount)
  hHi.setLen(hCount)
  hGlobal.setLen(hCount)

  let startX = nextInt(inputData, scanPos)
  let startY = nextInt(inputData, scanPos)
  let startLetter = nextUpper(inputData, scanPos)
  var startDir = northDir
  if startLetter == 'E': startDir = eastDir
  elif startLetter == 'S': startDir = southDir
  elif startLetter == 'W': startDir = westDir

  var startKind = verticalKind
  var startIndex = 0
  var found = false
  if startDir == eastDir or startDir == westDir:
    for k in 0..<hCount:
      if hY[k] == startY and startX >= hLo[k] and startX <= hHi[k]:
        startKind = horizontalKind
        startIndex = k
        found = true
        break
  else:
    for k in 0..<vCount:
      if vX[k] == startX and startY >= vLo[k] and startY <= vHi[k]:
        startKind = verticalKind
        startIndex = k
        found = true
        break
  if not found:
    for k in 0..<hCount:
      if hY[k] == startY and startX >= hLo[k] and startX <= hHi[k]:
        startKind = horizontalKind
        startIndex = k
        found = true
        break
  if not found:
    for k in 0..<vCount:
      if vX[k] == startX and startY >= vLo[k] and startY <= vHi[k]:
        startKind = verticalKind
        startIndex = k
        found = true
        break
  if not found:
    appendOutput("0")
    outputBuffer.add '\n'
    continue
```
The code splits corridors into vertical and horizontal arrays, then sorts their bounds. It locates the start corridor, preferring the direction of the heading and falling back to any corridor through the point.

**Node lists and crossings.**
```nim
  var vNodes = newSeq[seq[int]](vCount)
  for k in 0..<vCount:
    var nodes: seq[int] = @[vLo[k], vHi[k]]
    for l in 0..<hCount:
      if hY[l] >= vLo[k] and hY[l] <= vHi[k] and hLo[l] <= vX[k] and vX[k] <= hHi[l]:
        nodes.add hY[l]
    if startKind == verticalKind and startIndex == k:
      nodes.add startY
    vNodes[k] = sortedUnique(nodes)

  var hNodes = newSeq[seq[int]](hCount)
  for k in 0..<hCount:
    var nodes: seq[int] = @[hLo[k], hHi[k]]
    for l in 0..<vCount:
      if vX[l] >= hLo[k] and vX[l] <= hHi[k] and vLo[l] <= hY[k] and hY[k] <= vHi[l]:
        nodes.add vX[l]
    if startKind == horizontalKind and startIndex == k:
      nodes.add startX
    hNodes[k] = sortedUnique(nodes)

  var vCrossH = newSeq[seq[int]](vCount)
  for k in 0..<vCount:
    vCrossH[k] = newSeq[int](vNodes[k].len)
    for i in 0..<vNodes[k].len:
      vCrossH[k][i] = -1
  for k in 0..<hCount:
    for l in 0..<vCount:
      if vX[l] >= hLo[k] and vX[l] <= hHi[k] and vLo[l] <= hY[k] and hY[k] <= vHi[l]:
        let nodeIndex = findIndex(vNodes[l], hY[k])
        vCrossH[l][nodeIndex] = k

  var hCrossV = newSeq[seq[int]](hCount)
  for k in 0..<hCount:
    hCrossV[k] = newSeq[int](hNodes[k].len)
    for i in 0..<hNodes[k].len:
      hCrossV[k][i] = -1
  for k in 0..<vCount:
    for l in 0..<hCount:
      if vX[k] >= hLo[l] and vX[k] <= hHi[l] and vLo[k] <= hY[l] and hY[l] <= vHi[k]:
        let nodeIndex = findIndex(hNodes[l], vX[k])
        hCrossV[l][nodeIndex] = k
```
Each corridor gets a sorted node list of endpoints and crossing coordinates. `vCrossH` and `hCrossV` record which other corridor sits at each node.

**Walk and output.**
```nim
  var wasVisited = newSeq[bool](corridorCount)
  var visitedCount = 0
  var kind = startKind
  var corridorIndex = startIndex
  var nodeIndex = 0
  if kind == verticalKind:
    nodeIndex = findIndex(vNodes[startIndex], startY)
  else:
    nodeIndex = findIndex(hNodes[startIndex], startX)
  var heading = startDir

  while true:
    let globalId = if kind == verticalKind: vGlobal[corridorIndex] else: hGlobal[corridorIndex]
    if not wasVisited[globalId]:
      wasVisited[globalId] = true
      visitedCount += 1

    var canGo = [false, false, false, false]
    var pointX = 0
    var pointY = 0
    var crossingCorridor = -1
    if kind == verticalKind:
      pointX = vX[corridorIndex]
      pointY = vNodes[corridorIndex][nodeIndex]
      if pointY < vHi[corridorIndex]: canGo[northDir] = true
      if pointY > vLo[corridorIndex]: canGo[southDir] = true
      crossingCorridor = vCrossH[corridorIndex][nodeIndex]
      if crossingCorridor != -1:
        if pointX < hHi[crossingCorridor]: canGo[eastDir] = true
        if pointX > hLo[crossingCorridor]: canGo[westDir] = true
    else:
      pointX = hNodes[corridorIndex][nodeIndex]
      pointY = hY[corridorIndex]
      if pointX < hHi[corridorIndex]: canGo[eastDir] = true
      if pointX > hLo[corridorIndex]: canGo[westDir] = true
      crossingCorridor = hCrossV[corridorIndex][nodeIndex]
      if crossingCorridor != -1:
        if pointY < vHi[crossingCorridor]: canGo[northDir] = true
        if pointY > vLo[crossingCorridor]: canGo[southDir] = true
    if crossingCorridor != -1:
      let crossId = if kind == verticalKind: hGlobal[crossingCorridor] else: vGlobal[crossingCorridor]
      if not wasVisited[crossId]:
        wasVisited[crossId] = true
        visitedCount += 1

    var chosen = -1
    for offset in [3, 0, 1, 2]:
      let candidate = (heading + offset) mod 4
      if canGo[candidate]:
        chosen = candidate
        break
    if chosen == -1: break

    var nextKind = kind
    var nextCorridor = corridorIndex
    var nextNode = nodeIndex
    if kind == verticalKind:
      if chosen == northDir:
        nextNode = nodeIndex + 1
      elif chosen == southDir:
        nextNode = nodeIndex - 1
      else:
        nextKind = horizontalKind
        nextCorridor = vCrossH[corridorIndex][nodeIndex]
        let base = findIndex(hNodes[nextCorridor], pointX)
        if chosen == eastDir:
          nextNode = base + 1
        else:
          nextNode = base - 1
    else:
      if chosen == eastDir:
        nextNode = nodeIndex + 1
      elif chosen == westDir:
        nextNode = nodeIndex - 1
      else:
        nextKind = verticalKind
        nextCorridor = hCrossV[corridorIndex][nodeIndex]
        let base = findIndex(vNodes[nextCorridor], pointY)
        if chosen == northDir:
          nextNode = base + 1
        else:
          nextNode = base - 1

    kind = nextKind
    corridorIndex = nextCorridor
    nodeIndex = nextNode
    heading = chosen

    if kind == verticalKind:
      pointX = vX[corridorIndex]
      pointY = vNodes[corridorIndex][nodeIndex]
    else:
      pointX = hNodes[corridorIndex][nodeIndex]
      pointY = hY[corridorIndex]
    if pointX == startX and pointY == startY:
      break

  appendOutput($(corridorCount - visitedCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```
The loop marks the current and crossing corridors, fills `canGo`, and picks the first exit in left, straight, right, back order. It stops at the start point and prints the unvisited count.

## Complexity

Setup cost is bounded by the corridor product.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | one pass over input bytes | input bytes |
| Corridor parse | O(N) | O(N) arrays |
| Node lists | O(V times H) | O(V plus H) nodes |
| Walk | O(steps times log 500) | O(N) flags |
| Output | one write per block | flushBlockBytes |

At most 500 corridors per direction keep the product manageable.

| Measure | Big O |
| --- | --- |
| Time per map | O(V times H plus steps log N) |
| Space per map | O(N) |

Rechecking geometry at every unit step would pay for each coordinate twice, while node lists settle each crossing once.

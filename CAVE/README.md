## Problem

Read several cave maps. Each map lists horizontal and vertical corridor segments and one entry point with a heading. The explorer walks the corridors, prefers a left turn, then goes straight, then turns right, then turns back. He stops on reaching the entry point again. Print the number of corridors he never visited, one answer per map.

| Quantity | Bound |
| --- | --- |
| Maps | 20 |
| Corridors per map | 1000, at most 500 of each direction |
| Coordinate magnitude | 32767 |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

The corridor count stays small, so precomputation per map costs little.

## Idea

The turn rule walks one face boundary of the corridor graph, so every visited point matters. A corridor counts as visited when the walk reaches any point on it, including a crossing. The program splits corridors at crossings and endpoints into sorted node lists and walks node to node.

Each step costs O(log 500) to find a node on the new corridor. Building all lists costs O(V · H) per map.

## Why It Works

At a node, at most one vertical and one horizontal corridor meet. So at most four outgoing directions exist, and the program stores them in a four-slot table. The successor rule visits left, straight, right, back in that order. This rule permutes the directed pieces, so the walk must return to its start. Standing on a crossing touches both corridors, so the program marks both.

A vertical corridor at x holds its two endpoints in the node list. It also holds every horizontal y with hLo ≤ x ≤ hHi and vLo ≤ y ≤ vHi. A north move steps from node index k to k + 1. A south move steps to k − 1. A turn onto a horizontal corridor finds the shared x by binary search, then steps ±1 from that index.

The Python oracle walks one grid unit at a time and checks corridor geometry at every point. The first sample map gives this trace:

> sample corridors: 6
> visited ids: [0, 1, 2, 3, 4]
> unvisited ids: [5]
> turn points (x, y, from, to): [(0, 0, 'W', 'E'), (1, 0, 'E', 'N'), (1, 4, 'N', 'S'), (1, 2, 'S', 'E'), (5, 2, 'E', 'N'), (5, 3, 'N', 'S'), (5, 2, 'S', 'E'), (6, 2, 'E', 'W'), (5, 2, 'W', 'S'), (5, 0, 'S', 'E')]

Only the corridor at input index 5 stays unvisited, so the answer is 1.

## Code

The input buffer, hand scanner, and output buffer handle all input in one pass.

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
```

The scanner keeps ASCII and Unicode minus signs, so negative coordinates survive. The loop reads every line once. The output buffer flushes once at 256 KiB.

```nim
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

Each node list is sorted and deduplicated once. Binary search runs in O(log 500) on the longest list.

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
```

The loop runs once per corridor, so the parsing cost is O(corridorCount). Horizontal lines read their fixed coordinate first. Swapping endpoints keeps every range ordered.

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
```

The nested loops compare every vertical with every horizontal, so the cost is O(V · H). The start point joins its own list before sorting, which makes it a real node.

```nim
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

A −1 link means no perpendicular corridor meets that node. Each crossing fills one slot in each direction, which replaces a scan of all corridors during the walk.

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
```

The program marks the linked crossing corridor as visited without stepping onto it. The offsets 3, 0, 1, 2 mean left, straight, right, back. The four-slot table avoids a turn test against raw coordinates. One step costs O(1) here.

```nim
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

A turn crosses to the linked corridor and finds the shared node by binary search. The walk ends on the second arrival at the start point. The final write flushes the whole output buffer once.

## Complexity

Reading costs O(total tokens). Node lists cost O(V · H log(V + H)) to build, since each list holds up to H crossings. Cross links cost O(V · H log 500). The walk visits at most O(V · H) directed pieces, each in O(log 500). Total time per map is O(V · H log(V + H)); total space is O(V · H).

Walking one grid unit at a time would cost O(coordinate span) per corridor, which has no useful bound here.

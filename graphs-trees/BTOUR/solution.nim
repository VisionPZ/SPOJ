const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infinity = high(int64) div 4

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var nodeCount = 0
var adjHead = newSeq[int](1005)
var adjTo = newSeq[int](8200)
var adjWeight = newSeq[int](8200)
var adjNext = newSeq[int](8200)
var bestDist = newSeq[int64](1005)
var pathWays = newSeq[int64](1005)
var heapDist = newSeq[int64](8200)
var heapVert = newSeq[int](8200)
var heapSize = 0

proc heapPush(distValue: int64, vertex: int) =
  var idx = heapSize
  heapSize += 1
  heapDist[idx] = distValue
  heapVert[idx] = vertex
  while idx > 0:
    let parentIdx = (idx - 1) div 2
    if heapDist[parentIdx] <= heapDist[idx]: break
    swap heapDist[parentIdx], heapDist[idx]
    swap heapVert[parentIdx], heapVert[idx]
    idx = parentIdx

proc heapPop(): tuple[dist: int64, vertex: int] =
  result = (heapDist[0], heapVert[0])
  heapSize -= 1
  if heapSize > 0:
    heapDist[0] = heapDist[heapSize]
    heapVert[0] = heapVert[heapSize]
    var idx = 0
    while true:
      let leftIdx = 2 * idx + 1
      let rightIdx = 2 * idx + 2
      var smallest = idx
      if leftIdx < heapSize and heapDist[leftIdx] < heapDist[smallest]: smallest = leftIdx
      if rightIdx < heapSize and heapDist[rightIdx] < heapDist[smallest]: smallest = rightIdx
      if smallest == idx: break
      swap heapDist[smallest], heapDist[idx]
      swap heapVert[smallest], heapVert[idx]
      idx = smallest

proc runDijkstra(startVert, restrictAbove: int, pruneLimit: int64) =
  for nodeIdx in 0 .. nodeCount - 1:
    bestDist[nodeIdx] = infinity
    pathWays[nodeIdx] = 0
  heapSize = 0
  bestDist[startVert] = 0
  pathWays[startVert] = 1
  heapPush(0, startVert)
  while heapSize > 0:
    let topItem = heapPop()
    let curDist = topItem.dist
    let vertex = topItem.vertex
    if curDist > bestDist[vertex]: continue
    if curDist > pruneLimit: break
    var edgeIdx = adjHead[vertex]
    while edgeIdx != -1:
      let neighbor = adjTo[edgeIdx]
      if neighbor > restrictAbove:
        let nextDist = curDist + int64(adjWeight[edgeIdx])
        if nextDist < bestDist[neighbor]:
          bestDist[neighbor] = nextDist
          pathWays[neighbor] = pathWays[vertex]
          heapPush(nextDist, neighbor)
        elif nextDist == bestDist[neighbor]:
          pathWays[neighbor] += pathWays[vertex]
      edgeIdx = adjNext[edgeIdx]

let caseCount = nextInt(inputData, scanPos)
for caseIdx in 0 .. caseCount - 1:
  nodeCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  for i in 0 .. nodeCount - 1: adjHead[i] = -1
  var edgeSlot = 0
  var bestLen = infinity
  var bestCount: int64 = 0
  for edgeIdx in 0 .. edgeCount - 1:
    let fromVert = nextInt(inputData, scanPos) - 1
    let toVert = nextInt(inputData, scanPos) - 1
    let weight = nextInt(inputData, scanPos)
    if fromVert == toVert:
      let selfLen = int64(weight)
      if selfLen < bestLen:
        bestLen = selfLen
        bestCount = 1
      elif selfLen == bestLen:
        bestCount += 1
    else:
      adjTo[edgeSlot] = toVert
      adjWeight[edgeSlot] = weight
      adjNext[edgeSlot] = adjHead[fromVert]
      adjHead[fromVert] = edgeSlot
      edgeSlot += 1
      adjTo[edgeSlot] = fromVert
      adjWeight[edgeSlot] = weight
      adjNext[edgeSlot] = adjHead[toVert]
      adjHead[toVert] = edgeSlot
      edgeSlot += 1
  for rootVert in 0 .. nodeCount - 1:
    var neighborVert: array[8, int]
    var neighborWeight: array[8, int]
    var neighborCount = 0
    var edgeIdx = adjHead[rootVert]
    while edgeIdx != -1:
      let neighbor = adjTo[edgeIdx]
      if neighbor > rootVert and neighborCount < 8:
        neighborVert[neighborCount] = neighbor
        neighborWeight[neighborCount] = adjWeight[edgeIdx]
        neighborCount += 1
      edgeIdx = adjNext[edgeIdx]
    if neighborCount < 2: continue
    for firstIdx in 0 .. neighborCount - 1:
      if firstIdx == neighborCount - 1: continue
      let startVert = neighborVert[firstIdx]
      let startWeight = neighborWeight[firstIdx]
      var minEndWeight = 1000000000
      for secondIdx in firstIdx + 1 .. neighborCount - 1:
        if neighborWeight[secondIdx] < minEndWeight: minEndWeight = neighborWeight[secondIdx]
      var pruneLimit = infinity
      if bestLen < infinity:
        if int64(startWeight + minEndWeight + 1) > bestLen: continue
        pruneLimit = bestLen - int64(startWeight) - int64(minEndWeight)
      runDijkstra(startVert, rootVert, pruneLimit)
      for secondIdx in firstIdx + 1 .. neighborCount - 1:
        let endVert = neighborVert[secondIdx]
        if bestDist[endVert] >= infinity div 2: continue
        let cycleLen = int64(startWeight) + bestDist[endVert] + int64(neighborWeight[secondIdx])
        if cycleLen < bestLen:
          bestLen = cycleLen
          bestCount = pathWays[endVert]
        elif cycleLen == bestLen:
          bestCount += pathWays[endVert]
  if bestLen == infinity:
    appendOutput("0 0")
  else:
    appendOutput($bestLen)
    outputBuffer.add ' '
    appendOutput($bestCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

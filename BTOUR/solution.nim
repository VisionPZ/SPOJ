const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infinity = high(int64) div 4

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
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
var adjW = newSeq[int](8200)
var adjNext = newSeq[int](8200)
var distArr = newSeq[int64](1005)
var waysArr = newSeq[int64](1005)
var heapDist = newSeq[int64](8200)
var heapVert = newSeq[int](8200)
var heapSize = 0

proc heapPush(value: int64, vert: int) =
  var i = heapSize
  heapSize += 1
  heapDist[i] = value
  heapVert[i] = vert
  while i > 0:
    let p = (i - 1) div 2
    if heapDist[p] <= heapDist[i]: break
    swap heapDist[p], heapDist[i]
    swap heapVert[p], heapVert[i]
    i = p

proc heapPop(): tuple[d: int64, v: int] =
  result = (heapDist[0], heapVert[0])
  heapSize -= 1
  if heapSize > 0:
    heapDist[0] = heapDist[heapSize]
    heapVert[0] = heapVert[heapSize]
    var i = 0
    while true:
      let l = 2 * i + 1
      let r = 2 * i + 2
      var smallest = i
      if l < heapSize and heapDist[l] < heapDist[smallest]: smallest = l
      if r < heapSize and heapDist[r] < heapDist[smallest]: smallest = r
      if smallest == i: break
      swap heapDist[smallest], heapDist[i]
      swap heapVert[smallest], heapVert[i]
      i = smallest

proc runDijkstra(startVert, restrictAbove: int, pruneLimit: int64) =
  for i in 0 .. nodeCount - 1:
    distArr[i] = infinity
    waysArr[i] = 0
  heapSize = 0
  distArr[startVert] = 0
  waysArr[startVert] = 1
  heapPush(0, startVert)
  while heapSize > 0:
    let cur = heapPop()
    let d = cur.d
    let u = cur.v
    if d > distArr[u]: continue
    if d > pruneLimit: break
    var e = adjHead[u]
    while e != -1:
      let t = adjTo[e]
      if t > restrictAbove:
        let nd = d + int64(adjW[e])
        if nd < distArr[t]:
          distArr[t] = nd
          waysArr[t] = waysArr[u]
          heapPush(nd, t)
        elif nd == distArr[t]:
          waysArr[t] += waysArr[u]
      e = adjNext[e]

let caseCount = nextInt(inputData, scanPos)
for caseIdx in 0 .. caseCount - 1:
  nodeCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  for i in 0 .. nodeCount - 1: adjHead[i] = -1
  var edgeSlot = 0
  var bestLen = infinity
  var bestCount: int64 = 0
  for e in 0 .. edgeCount - 1:
    let u = nextInt(inputData, scanPos) - 1
    let v = nextInt(inputData, scanPos) - 1
    let w = nextInt(inputData, scanPos)
    if u == v:
      let selfLen = int64(w)
      if selfLen < bestLen:
        bestLen = selfLen
        bestCount = 1
      elif selfLen == bestLen:
        bestCount += 1
    else:
      adjTo[edgeSlot] = v
      adjW[edgeSlot] = w
      adjNext[edgeSlot] = adjHead[u]
      adjHead[u] = edgeSlot
      edgeSlot += 1
      adjTo[edgeSlot] = u
      adjW[edgeSlot] = w
      adjNext[edgeSlot] = adjHead[v]
      adjHead[v] = edgeSlot
      edgeSlot += 1
  for s in 0 .. nodeCount - 1:
    var neighborVert: array[8, int]
    var neighborW: array[8, int]
    var neighborCount = 0
    var e = adjHead[s]
    while e != -1:
      let t = adjTo[e]
      if t > s and neighborCount < 8:
        neighborVert[neighborCount] = t
        neighborW[neighborCount] = adjW[e]
        neighborCount += 1
      e = adjNext[e]
    if neighborCount < 2: continue
    for i in 0 .. neighborCount - 1:
      if i == neighborCount - 1: continue
      let startVert = neighborVert[i]
      let startW = neighborW[i]
      var minEndW = 1000000000
      for j in i + 1 .. neighborCount - 1:
        if neighborW[j] < minEndW: minEndW = neighborW[j]
      var pruneLimit = infinity
      if bestLen < infinity:
        if int64(startW + minEndW + 1) > bestLen: continue
        pruneLimit = bestLen - int64(startW) - int64(minEndW)
      runDijkstra(startVert, s, pruneLimit)
      for j in i + 1 .. neighborCount - 1:
        let endVert = neighborVert[j]
        if distArr[endVert] >= infinity div 2: continue
        let cycleLen = int64(startW) + distArr[endVert] + int64(neighborW[j])
        if cycleLen < bestLen:
          bestLen = cycleLen
          bestCount = waysArr[endVert]
        elif cycleLen == bestLen:
          bestCount += waysArr[endVert]
  if bestLen == infinity:
    appendOutput("0 0")
  else:
    appendOutput($bestLen)
    outputBuffer.add ' '
    appendOutput($bestCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

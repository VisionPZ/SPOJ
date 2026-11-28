{.push warning[Deprecated]: off.}
{.define: release.}
{.pop.}
{.push checks: off.}
{.passC: "-O3".}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

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
var edgeCount = 0
var adjStart: seq[int] = @[]
var adjFill: seq[int] = @[]
var adjTo: seq[int] = @[]
var adjWeight: seq[int] = @[]
var rawSource: seq[int] = @[]
var rawTo: seq[int] = @[]
var rawWeight: seq[int] = @[]

var labelLimit = 0
var labelCount: seq[int] = @[]
var labelList: seq[int] = @[]
var answerTable: seq[int] = @[]

var weightBound = 1
var bucketModulus = 2
var bucketMask = 1
var bucketHead: seq[int] = @[]
var bucketVertex: seq[int] = @[]
var bucketNext: seq[int] = @[]
var bucketSlotCount = 0
var bucketEntryCount = 0
var currentDistance = 0
var poppedVertex = 0
var fullCount = 0
var minWorst = 0
var minWorstVertex = -1

proc bucketPush(distance, vertex: int) {.inline.} =
  let slot = bucketSlotCount
  bucketSlotCount += 1
  bucketVertex[slot] = vertex
  let bucket = distance and bucketMask
  bucketNext[slot] = bucketHead[bucket]
  bucketHead[bucket] = slot
  bucketEntryCount += 1

proc bucketPop() {.inline.} =
  while bucketHead[currentDistance and bucketMask] == -1:
    currentDistance += 1
  let bucket = currentDistance and bucketMask
  let slot = bucketHead[bucket]
  bucketHead[bucket] = bucketNext[slot]
  poppedVertex = bucketVertex[slot]
  bucketEntryCount -= 1

proc recomputeMinWorst() {.inline.} =
  minWorst = high(int)
  minWorstVertex = -1
  for vertex in 0 .. nodeCount - 1:
    if labelCount[vertex] == labelLimit:
      let worst = labelList[vertex * labelLimit + labelLimit - 1]
      if worst < minWorst:
        minWorst = worst
        minWorstVertex = vertex

proc insertLabel(vertex, distance: int) {.inline.} =
  let base = vertex * labelLimit
  let count = labelCount[vertex]
  var pos = 0
  while pos < count and labelList[base + pos] < distance:
    pos += 1
  var shift = count
  while shift > pos:
    labelList[base + shift] = labelList[base + shift - 1]
    shift -= 1
  labelList[base + pos] = distance
  labelCount[vertex] = count + 1
  if count == labelLimit:
    if vertex == minWorstVertex:
      recomputeMinWorst()
    elif labelList[base + labelLimit - 1] < minWorst:
      minWorst = labelList[base + labelLimit - 1]
      minWorstVertex = vertex
  elif count + 1 == labelLimit:
    fullCount += 1
    let worst = labelList[base + labelLimit - 1]
    if worst < minWorst:
      minWorst = worst
      minWorstVertex = vertex

proc solveSource(source: int) =
  for bucket in 0 .. bucketModulus - 1:
    bucketHead[bucket] = -1
  for vertex in 0 .. nodeCount - 1:
    labelCount[vertex] = 0
  bucketSlotCount = 0
  bucketEntryCount = 0
  currentDistance = 0
  fullCount = 0
  minWorst = high(int)
  minWorstVertex = -1
  bucketPush(0, source)
  while bucketEntryCount > 0:
    bucketPop()
    let distance = currentDistance
    let vertex = poppedVertex
    if distance > 0:
      let base = vertex * labelLimit
      let count = labelCount[vertex]
      if count == labelLimit and distance >= labelList[base + labelLimit - 1]:
        continue
      insertLabel(vertex, distance)
    if fullCount == nodeCount and distance + 1 >= minWorst:
      continue
    var edge = adjStart[vertex]
    let edgeEnd = adjStart[vertex + 1]
    while edge < edgeEnd:
      let target = adjTo[edge]
      let candidate = distance + adjWeight[edge]
      let targetBase = target * labelLimit
      let targetCount = labelCount[target]
      if targetCount < labelLimit or candidate < labelList[targetBase + labelLimit - 1]:
        bucketPush(candidate, target)
      edge += 1
  for vertex in 0 .. nodeCount - 1:
    let answerBase = (source * nodeCount + vertex) * labelLimit
    let labelBase = vertex * labelLimit
    for idx in 0 .. labelLimit - 1:
      answerTable[answerBase + idx] = -1
    for idx in 0 .. labelCount[vertex] - 1:
      answerTable[answerBase + idx] = labelList[labelBase + idx]

var queryFrom: seq[int] = @[]
var queryTo: seq[int] = @[]
var queryRank: seq[int] = @[]

let caseCount = nextInt(inputData, scanPos)
for caseIdx in 0 .. caseCount - 1:
  nodeCount = nextInt(inputData, scanPos)
  edgeCount = nextInt(inputData, scanPos)
  adjStart.setLen(nodeCount + 1)
  adjFill.setLen(nodeCount)
  rawSource.setLen(edgeCount)
  rawTo.setLen(edgeCount)
  rawWeight.setLen(edgeCount)
  for vertex in 0 .. nodeCount - 1:
    adjFill[vertex] = 0
  weightBound = 1
  for edge in 0 .. edgeCount - 1:
    let fromTown = nextInt(inputData, scanPos) - 1
    let toTown = nextInt(inputData, scanPos) - 1
    let roadLength = nextInt(inputData, scanPos)
    rawSource[edge] = fromTown
    rawTo[edge] = toTown
    rawWeight[edge] = roadLength
    adjFill[fromTown] += 1
    if roadLength > weightBound:
      weightBound = roadLength
  adjStart[0] = 0
  for vertex in 0 .. nodeCount - 1:
    adjStart[vertex + 1] = adjStart[vertex] + adjFill[vertex]
    adjFill[vertex] = adjStart[vertex]
  adjTo.setLen(edgeCount)
  adjWeight.setLen(edgeCount)
  for edge in 0 .. edgeCount - 1:
    let slot = adjFill[rawSource[edge]]
    adjFill[rawSource[edge]] += 1
    adjTo[slot] = rawTo[edge]
    adjWeight[slot] = rawWeight[edge]
  bucketModulus = 1
  while bucketModulus <= weightBound:
    bucketModulus = bucketModulus shl 1
  bucketMask = bucketModulus - 1
  let queryCount = nextInt(inputData, scanPos)
  queryFrom.setLen(queryCount)
  queryTo.setLen(queryCount)
  queryRank.setLen(queryCount)
  labelLimit = 0
  for query in 0 .. queryCount - 1:
    queryFrom[query] = nextInt(inputData, scanPos) - 1
    queryTo[query] = nextInt(inputData, scanPos) - 1
    queryRank[query] = nextInt(inputData, scanPos)
    if queryRank[query] > labelLimit:
      labelLimit = queryRank[query]
  labelCount.setLen(nodeCount)
  labelList.setLen(nodeCount * labelLimit)
  answerTable.setLen(nodeCount * nodeCount * labelLimit)
  bucketHead.setLen(bucketModulus)
  let slotCapacity = (labelLimit + 1) * (edgeCount + 1) + nodeCount + 10
  bucketVertex.setLen(slotCapacity)
  bucketNext.setLen(slotCapacity)
  for source in 0 .. nodeCount - 1:
    solveSource(source)
  if caseIdx > 0:
    outputBuffer.add '\n'
  for query in 0 .. queryCount - 1:
    let answerPos = (queryFrom[query] * nodeCount + queryTo[query]) * labelLimit +
                    queryRank[query] - 1
    appendOutput($answerTable[answerPos])
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

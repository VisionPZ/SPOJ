{.push checks: off.}
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const farDistance = 1000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let nodeCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  let runnerStart = nextInt(inputData, scanPos) - 1
  let chaserStart = nextInt(inputData, scanPos) - 1

  var head = newSeq[int](nodeCount)
  for nodeIdx in 0..<nodeCount:
    head[nodeIdx] = -1
  var neighborTo = newSeq[int](2 * edgeCount)
  var neighborNext = newSeq[int](2 * edgeCount)
  var degree = newSeq[int](nodeCount)
  var edgeSlot = 0
  for edgeIndex in 0..<edgeCount:
    let fromNode = nextInt(inputData, scanPos) - 1
    let toNode = nextInt(inputData, scanPos) - 1
    neighborTo[edgeSlot] = toNode
    neighborNext[edgeSlot] = head[fromNode]
    head[fromNode] = edgeSlot
    edgeSlot += 1
    degree[fromNode] += 1
    neighborTo[edgeSlot] = fromNode
    neighborNext[edgeSlot] = head[toNode]
    head[toNode] = edgeSlot
    edgeSlot += 1
    degree[toNode] += 1

  let stateCount = nodeCount * nodeCount
  var isClosed = newSeq[bool](stateCount)
  for nodeIdx in 0..<nodeCount:
    isClosed[nodeIdx * nodeCount + nodeIdx] = true
    var edgeIdx = head[nodeIdx]
    while edgeIdx != -1:
      isClosed[nodeIdx * nodeCount + neighborTo[edgeIdx]] = true
      edgeIdx = neighborNext[edgeIdx]

  var removed = newSeq[bool](nodeCount)
  var peelDegree = newSeq[int](nodeCount)
  var queue = newSeq[int](nodeCount)
  var queueHead = 0
  var queueTail = 0
  for nodeIdx in 0..<nodeCount:
    peelDegree[nodeIdx] = degree[nodeIdx]
    if degree[nodeIdx] <= 1:
      queue[queueTail] = nodeIdx
      queueTail += 1
  while queueHead < queueTail:
    let vertex = queue[queueHead]
    queueHead += 1
    if removed[vertex]:
      continue
    removed[vertex] = true
    var edgeIdx = head[vertex]
    while edgeIdx != -1:
      let neighbor = neighborTo[edgeIdx]
      if not removed[neighbor]:
        peelDegree[neighbor] -= 1
        if peelDegree[neighbor] == 1:
          queue[queueTail] = neighbor
          queueTail += 1
      edgeIdx = neighborNext[edgeIdx]

  var distToCore = newSeq[int](nodeCount)
  for nodeIdx in 0..<nodeCount:
    distToCore[nodeIdx] = farDistance
  queueHead = 0
  queueTail = 0
  for nodeIdx in 0..<nodeCount:
    if not removed[nodeIdx]:
      distToCore[nodeIdx] = 0
      queue[queueTail] = nodeIdx
      queueTail += 1
  while queueHead < queueTail:
    let vertex = queue[queueHead]
    queueHead += 1
    var edgeIdx = head[vertex]
    while edgeIdx != -1:
      let neighbor = neighborTo[edgeIdx]
      if distToCore[neighbor] == farDistance:
        distToCore[neighbor] = distToCore[vertex] + 1
        queue[queueTail] = neighbor
        queueTail += 1
      edgeIdx = neighborNext[edgeIdx]

  var runnerWins = false
  if not removed[runnerStart]:
    runnerWins = true
  elif distToCore[runnerStart] != farDistance:
    var distFromChaser = newSeq[int](nodeCount)
    for nodeIdx in 0..<nodeCount:
      distFromChaser[nodeIdx] = farDistance
    queueHead = 0
    queueTail = 0
    distFromChaser[chaserStart] = 0
    queue[queueTail] = chaserStart
    queueTail += 1
    while queueHead < queueTail:
      let vertex = queue[queueHead]
      queueHead += 1
      var edgeIdx = head[vertex]
      while edgeIdx != -1:
        let neighbor = neighborTo[edgeIdx]
        if distFromChaser[neighbor] == farDistance:
          distFromChaser[neighbor] = distFromChaser[vertex] + 1
          queue[queueTail] = neighbor
          queueTail += 1
        edgeIdx = neighborNext[edgeIdx]
    var current = runnerStart
    var steps = 0
    while true:
      if distFromChaser[current] <= steps:
        break
      if distToCore[current] == 0:
        runnerWins = true
        break
      var edgeIdx = head[current]
      var nextVertex = -1
      while edgeIdx != -1:
        let neighbor = neighborTo[edgeIdx]
        if distToCore[neighbor] < distToCore[current]:
          nextVertex = neighbor
          break
        edgeIdx = neighborNext[edgeIdx]
      if nextVertex < 0:
        break
      current = nextVertex
      steps += 1

  if runnerWins:
    appendOutput("No")
    outputBuffer.add '\n'
    continue

  var finalizedRunner = newSeq[bool](stateCount)
  var finalizedChaser = newSeq[bool](stateCount)
  var pushedChaser = newSeq[bool](stateCount)
  var pending = newSeq[uint16](stateCount)
  for runnerPos in 0..<nodeCount:
    let startCount = uint16(degree[runnerPos] + 1)
    let base = runnerPos * nodeCount
    for chaserPos in 0..<nodeCount:
      pending[base + chaserPos] = startCount

  let maxBucket = nodeCount + 4
  var bucketHead = newSeq[int32](maxBucket + 1)
  var eventNext = newSeq[int32](2 * stateCount)

  for runnerPos in 0..<nodeCount:
    var code = (runnerPos * nodeCount + runnerPos) * 2 + 1
    eventNext[code] = bucketHead[0]
    bucketHead[0] = int32(code + 1)
    var edgeIdx = head[runnerPos]
    while edgeIdx != -1:
      code = (runnerPos * nodeCount + neighborTo[edgeIdx]) * 2 + 1
      eventNext[code] = bucketHead[1]
      bucketHead[1] = int32(code + 1)
      edgeIdx = neighborNext[edgeIdx]

  var answer = -1
  let targetState = runnerStart * nodeCount + chaserStart
  for value in 0..maxBucket:
    while bucketHead[value] != 0:
      let code = int(bucketHead[value]) - 1
      bucketHead[value] = eventNext[code]
      let eventType = code and 1
      let state = code shr 1
      let runnerPos = state div nodeCount
      let chaserPos = state - runnerPos * nodeCount
      if eventType == 1:
        if finalizedChaser[state]:
          continue
        finalizedChaser[state] = true
        var runnerState = runnerPos * nodeCount + chaserPos
        if not finalizedRunner[runnerState]:
          pending[runnerState] = pending[runnerState] - uint16(1)
          if pending[runnerState] == uint16(0):
            finalizedRunner[runnerState] = true
            let nextCode = runnerState * 2
            eventNext[nextCode] = bucketHead[value]
            bucketHead[value] = int32(nextCode + 1)
        var edgeIdx = head[runnerPos]
        while edgeIdx != -1:
          runnerState = neighborTo[edgeIdx] * nodeCount + chaserPos
          if not finalizedRunner[runnerState]:
            pending[runnerState] = pending[runnerState] - uint16(1)
            if pending[runnerState] == uint16(0):
              finalizedRunner[runnerState] = true
              let nextCode = runnerState * 2
              eventNext[nextCode] = bucketHead[value]
              bucketHead[value] = int32(nextCode + 1)
          edgeIdx = neighborNext[edgeIdx]
      else:
        if state == targetState:
          answer = value
          break
        var chaserState = runnerPos * nodeCount + chaserPos
        if not finalizedChaser[chaserState] and not pushedChaser[chaserState]:
          if not isClosed[chaserState]:
            pushedChaser[chaserState] = true
            let nextValue = value + 1
            if nextValue <= maxBucket:
              let nextCode = chaserState * 2 + 1
              eventNext[nextCode] = bucketHead[nextValue]
              bucketHead[nextValue] = int32(nextCode + 1)
        var edgeIdx = head[chaserPos]
        while edgeIdx != -1:
          chaserState = runnerPos * nodeCount + neighborTo[edgeIdx]
          if not finalizedChaser[chaserState] and not pushedChaser[chaserState]:
            if not isClosed[chaserState]:
              pushedChaser[chaserState] = true
              let nextValue = value + 1
              if nextValue <= maxBucket:
                let nextCode = chaserState * 2 + 1
                eventNext[nextCode] = bucketHead[nextValue]
                bucketHead[nextValue] = int32(nextCode + 1)
          edgeIdx = neighborNext[edgeIdx]
    if answer >= 0:
      break

  if answer < 0:
    appendOutput("No")
  else:
    appendOutput($(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

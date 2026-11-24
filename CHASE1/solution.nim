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
  for i in 0..<nodeCount:
    head[i] = -1
  var neighborTo = newSeq[int](2 * edgeCount)
  var neighborNext = newSeq[int](2 * edgeCount)
  var degree = newSeq[int](nodeCount)
  var edgeSlot = 0
  for edgeIndex in 0..<edgeCount:
    let u = nextInt(inputData, scanPos) - 1
    let v = nextInt(inputData, scanPos) - 1
    neighborTo[edgeSlot] = v
    neighborNext[edgeSlot] = head[u]
    head[u] = edgeSlot
    edgeSlot += 1
    degree[u] += 1
    neighborTo[edgeSlot] = u
    neighborNext[edgeSlot] = head[v]
    head[v] = edgeSlot
    edgeSlot += 1
    degree[v] += 1

  let stateCount = nodeCount * nodeCount
  var closedFlag = newSeq[bool](stateCount)
  for i in 0..<nodeCount:
    closedFlag[i * nodeCount + i] = true
    var e = head[i]
    while e != -1:
      closedFlag[i * nodeCount + neighborTo[e]] = true
      e = neighborNext[e]

  var removed = newSeq[bool](nodeCount)
  var peelDegree = newSeq[int](nodeCount)
  var queue = newSeq[int](nodeCount)
  var queueHead = 0
  var queueTail = 0
  for i in 0..<nodeCount:
    peelDegree[i] = degree[i]
    if degree[i] <= 1:
      queue[queueTail] = i
      queueTail += 1
  while queueHead < queueTail:
    let u = queue[queueHead]
    queueHead += 1
    if removed[u]:
      continue
    removed[u] = true
    var e = head[u]
    while e != -1:
      let v = neighborTo[e]
      if not removed[v]:
        peelDegree[v] -= 1
        if peelDegree[v] == 1:
          queue[queueTail] = v
          queueTail += 1
      e = neighborNext[e]

  var distToCore = newSeq[int](nodeCount)
  for i in 0..<nodeCount:
    distToCore[i] = farDistance
  queueHead = 0
  queueTail = 0
  for i in 0..<nodeCount:
    if not removed[i]:
      distToCore[i] = 0
      queue[queueTail] = i
      queueTail += 1
  while queueHead < queueTail:
    let u = queue[queueHead]
    queueHead += 1
    var e = head[u]
    while e != -1:
      let v = neighborTo[e]
      if distToCore[v] == farDistance:
        distToCore[v] = distToCore[u] + 1
        queue[queueTail] = v
        queueTail += 1
      e = neighborNext[e]

  var runnerWins = false
  if not removed[runnerStart]:
    runnerWins = true
  elif distToCore[runnerStart] != farDistance:
    var distFromChaser = newSeq[int](nodeCount)
    for i in 0..<nodeCount:
      distFromChaser[i] = farDistance
    queueHead = 0
    queueTail = 0
    distFromChaser[chaserStart] = 0
    queue[queueTail] = chaserStart
    queueTail += 1
    while queueHead < queueTail:
      let u = queue[queueHead]
      queueHead += 1
      var e = head[u]
      while e != -1:
        let v = neighborTo[e]
        if distFromChaser[v] == farDistance:
          distFromChaser[v] = distFromChaser[u] + 1
          queue[queueTail] = v
          queueTail += 1
        e = neighborNext[e]
    var current = runnerStart
    var steps = 0
    while true:
      if distFromChaser[current] <= steps:
        break
      if distToCore[current] == 0:
        runnerWins = true
        break
      var e = head[current]
      var nextVertex = -1
      while e != -1:
        let v = neighborTo[e]
        if distToCore[v] < distToCore[current]:
          nextVertex = v
          break
        e = neighborNext[e]
      if nextVertex < 0:
        break
      current = nextVertex
      steps += 1

  if runnerWins:
    appendOutput("No")
    outputBuffer.add '\n'
    continue

  var finalizedA = newSeq[bool](stateCount)
  var finalizedX = newSeq[bool](stateCount)
  var pushedX = newSeq[bool](stateCount)
  var pending = newSeq[uint16](stateCount)
  for r in 0..<nodeCount:
    let startCount = uint16(degree[r] + 1)
    let base = r * nodeCount
    for c in 0..<nodeCount:
      pending[base + c] = startCount

  let maxBucket = nodeCount + 4
  var bucketHead = newSeq[int32](maxBucket + 1)
  var eventNext = newSeq[int32](2 * stateCount)

  for r in 0..<nodeCount:
    var code = (r * nodeCount + r) * 2 + 1
    eventNext[code] = bucketHead[0]
    bucketHead[0] = int32(code + 1)
    var e = head[r]
    while e != -1:
      code = (r * nodeCount + neighborTo[e]) * 2 + 1
      eventNext[code] = bucketHead[1]
      bucketHead[1] = int32(code + 1)
      e = neighborNext[e]

  var answer = -1
  let targetState = runnerStart * nodeCount + chaserStart
  for value in 0..maxBucket:
    while bucketHead[value] != 0:
      let code = int(bucketHead[value]) - 1
      bucketHead[value] = eventNext[code]
      let eventType = code and 1
      let state = code shr 1
      let r = state div nodeCount
      let c = state - r * nodeCount
      if eventType == 1:
        if finalizedX[state]:
          continue
        finalizedX[state] = true
        var stateA = r * nodeCount + c
        if not finalizedA[stateA]:
          pending[stateA] = pending[stateA] - uint16(1)
          if pending[stateA] == uint16(0):
            finalizedA[stateA] = true
            let nextCode = stateA * 2
            eventNext[nextCode] = bucketHead[value]
            bucketHead[value] = int32(nextCode + 1)
        var e = head[r]
        while e != -1:
          stateA = neighborTo[e] * nodeCount + c
          if not finalizedA[stateA]:
            pending[stateA] = pending[stateA] - uint16(1)
            if pending[stateA] == uint16(0):
              finalizedA[stateA] = true
              let nextCode = stateA * 2
              eventNext[nextCode] = bucketHead[value]
              bucketHead[value] = int32(nextCode + 1)
          e = neighborNext[e]
      else:
        if state == targetState:
          answer = value
          break
        var stateX = r * nodeCount + c
        if not finalizedX[stateX] and not pushedX[stateX]:
          if not closedFlag[stateX]:
            pushedX[stateX] = true
            let nextValue = value + 1
            if nextValue <= maxBucket:
              let nextCode = stateX * 2 + 1
              eventNext[nextCode] = bucketHead[nextValue]
              bucketHead[nextValue] = int32(nextCode + 1)
        var e = head[c]
        while e != -1:
          stateX = r * nodeCount + neighborTo[e]
          if not finalizedX[stateX] and not pushedX[stateX]:
            if not closedFlag[stateX]:
              pushedX[stateX] = true
              let nextValue = value + 1
              if nextValue <= maxBucket:
                let nextCode = stateX * 2 + 1
                eventNext[nextCode] = bucketHead[nextValue]
                bucketHead[nextValue] = int32(nextCode + 1)
          e = neighborNext[e]
    if answer >= 0:
      break

  if answer < 0:
    appendOutput("No")
  else:
    appendOutput($(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

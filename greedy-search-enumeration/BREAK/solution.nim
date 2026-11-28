const flushBlockBytes = 1 shl 17

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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc popCount64(value: uint64): int =
  var current = value
  current = current - ((current shr 1) and 0x5555555555555555'u64)
  current = (current and 0x3333333333333333'u64) + ((current shr 2) and 0x3333333333333333'u64)
  current = (current + (current shr 4)) and 0x0F0F0F0F0F0F0F0F'u64
  return int((current * 0x0101010101010101'u64) shr 56)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let computerCount = nextInt(inputData, scanPos)
  let trustCount = nextInt(inputData, scanPos)
  var originalAdj = newSeq[seq[int]](computerCount)
  var reverseAdj = newSeq[seq[int]](computerCount)
  for computerIndex in 0 .. computerCount - 1:
    originalAdj[computerIndex] = newSeq[int](0)
    reverseAdj[computerIndex] = newSeq[int](0)
  var edgeFrom = newSeq[int](trustCount)
  var edgeTo = newSeq[int](trustCount)
  for edgeIndex in 0 .. trustCount - 1:
    let trustingComputer = nextInt(inputData, scanPos) - 1
    let trustedComputer = nextInt(inputData, scanPos) - 1
    edgeFrom[edgeIndex] = trustingComputer
    edgeTo[edgeIndex] = trustedComputer
    originalAdj[trustingComputer].add trustedComputer
    reverseAdj[trustedComputer].add trustingComputer

  var visited = newSeq[bool](computerCount)
  var finishOrder = newSeq[int](computerCount)
  var finishedCount = 0
  var stackNodes = newSeq[int](computerCount)
  var stackCursors = newSeq[int](computerCount)
  for startNode in 0 .. computerCount - 1:
    if visited[startNode]:
      continue
    var depth = 0
    stackNodes[0] = startNode
    stackCursors[0] = 0
    visited[startNode] = true
    while depth >= 0:
      let currentNode = stackNodes[depth]
      let cursor = stackCursors[depth]
      if cursor < reverseAdj[currentNode].len:
        let nextNode = reverseAdj[currentNode][cursor]
        stackCursors[depth] = cursor + 1
        if not visited[nextNode]:
          visited[nextNode] = true
          depth += 1
          stackNodes[depth] = nextNode
          stackCursors[depth] = 0
      else:
        finishOrder[finishedCount] = currentNode
        finishedCount += 1
        depth -= 1

  var componentOf = newSeq[int](computerCount)
  for computerIndex in 0 .. computerCount - 1:
    componentOf[computerIndex] = -1
  var componentCount = 0
  var pendingNodes = newSeq[int](computerCount)
  for orderIndex in countdown(finishedCount - 1, 0):
    let startNode = finishOrder[orderIndex]
    if componentOf[startNode] != -1:
      continue
    var stackTop = 0
    pendingNodes[0] = startNode
    componentOf[startNode] = componentCount
    while stackTop >= 0:
      let currentNode = pendingNodes[stackTop]
      stackTop -= 1
      for nextNode in originalAdj[currentNode]:
        if componentOf[nextNode] == -1:
          componentOf[nextNode] = componentCount
          stackTop += 1
          pendingNodes[stackTop] = nextNode
    componentCount += 1

  var dagAdj = newSeq[seq[int]](componentCount)
  for componentIndex in 0 .. componentCount - 1:
    dagAdj[componentIndex] = newSeq[int](0)
  for edgeIndex in 0 .. trustCount - 1:
    let reachSourceComponent = componentOf[edgeTo[edgeIndex]]
    let reachTargetComponent = componentOf[edgeFrom[edgeIndex]]
    if reachSourceComponent != reachTargetComponent:
      dagAdj[reachSourceComponent].add reachTargetComponent

  var indegree = newSeq[int](componentCount)
  for componentIndex in 0 .. componentCount - 1:
    for nextComponent in dagAdj[componentIndex]:
      indegree[nextComponent] += 1
  var queueNodes = newSeq[int](componentCount)
  var queueHead = 0
  var queueTail = 0
  for componentIndex in 0 .. componentCount - 1:
    if indegree[componentIndex] == 0:
      queueNodes[queueTail] = componentIndex
      queueTail += 1
  var topoOrder = newSeq[int](componentCount)
  var topoCount = 0
  while queueHead < queueTail:
    let currentComponent = queueNodes[queueHead]
    queueHead += 1
    topoOrder[topoCount] = currentComponent
    topoCount += 1
    for nextComponent in dagAdj[currentComponent]:
      indegree[nextComponent] -= 1
      if indegree[nextComponent] == 0:
        queueNodes[queueTail] = nextComponent
        queueTail += 1

  let wordCount = (computerCount + 63) div 64
  var reachBits = newSeq[uint64](componentCount * wordCount)
  for computerIndex in 0 .. computerCount - 1:
    let owner = componentOf[computerIndex] * wordCount + computerIndex div 64
    reachBits[owner] = reachBits[owner] or (uint64(1) shl (computerIndex mod 64))
  for orderIndex in countdown(topoCount - 1, 0):
    let currentComponent = topoOrder[orderIndex]
    for nextComponent in dagAdj[currentComponent]:
      for wordIndex in 0 .. wordCount - 1:
        let targetSlot = currentComponent * wordCount + wordIndex
        let sourceSlot = nextComponent * wordCount + wordIndex
        reachBits[targetSlot] = reachBits[targetSlot] or reachBits[sourceSlot]

  var componentImportance = newSeq[int](componentCount)
  for componentIndex in 0 .. componentCount - 1:
    var importance = 0
    for wordIndex in 0 .. wordCount - 1:
      importance += popCount64(reachBits[componentIndex * wordCount + wordIndex])
    componentImportance[componentIndex] = importance
  var bestImportance = -1
  for computerIndex in 0 .. computerCount - 1:
    if componentImportance[componentOf[computerIndex]] > bestImportance:
      bestImportance = componentImportance[componentOf[computerIndex]]
  var firstNumber = true
  for computerIndex in 0 .. computerCount - 1:
    if componentImportance[componentOf[computerIndex]] == bestImportance:
      if not firstNumber:
        outputBuffer.add ' '
      appendOutput($(computerIndex + 1))
      firstNumber = false
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

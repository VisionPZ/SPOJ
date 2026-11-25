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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let studentCount = nextInt(inputData, scanPos)
  let relationCount = nextInt(inputData, scanPos)
  let targetStudent = nextInt(inputData, scanPos)
  var forwardHead = newSeq[int](studentCount + 1)
  var backwardHead = newSeq[int](studentCount + 1)
  var indegree = newSeq[int](studentCount + 1)
  var edgeDestination = newSeq[int](relationCount)
  var edgeNext = newSeq[int](relationCount)
  var reverseDestination = newSeq[int](relationCount)
  var reverseNext = newSeq[int](relationCount)
  for nodeIndex in 0 .. studentCount:
    forwardHead[nodeIndex] = -1
    backwardHead[nodeIndex] = -1
  for edgeIndex in 0 .. relationCount - 1:
    let lowerStudent = nextInt(inputData, scanPos)
    let higherStudent = nextInt(inputData, scanPos)
    edgeDestination[edgeIndex] = higherStudent
    edgeNext[edgeIndex] = forwardHead[lowerStudent]
    forwardHead[lowerStudent] = edgeIndex
    reverseDestination[edgeIndex] = lowerStudent
    reverseNext[edgeIndex] = backwardHead[higherStudent]
    backwardHead[higherStudent] = edgeIndex
    indegree[higherStudent] += 1
  var traversalQueue = newSeq[int](studentCount)
  var queueHead = 0
  var queueTail = 0
  for nodeIndex in 1 .. studentCount:
    if indegree[nodeIndex] == 0:
      traversalQueue[queueTail] = nodeIndex
      queueTail += 1
  while queueHead < queueTail:
    let currentNode = traversalQueue[queueHead]
    queueHead += 1
    var edgeIndex = forwardHead[currentNode]
    while edgeIndex != -1:
      let neighbor = edgeDestination[edgeIndex]
      indegree[neighbor] -= 1
      if indegree[neighbor] == 0:
        traversalQueue[queueTail] = neighbor
        queueTail += 1
      edgeIndex = edgeNext[edgeIndex]
  if queueTail != studentCount:
    appendOutput("-1")
    outputBuffer.add '\n'
    continue
  var visited = newSeq[bool](studentCount + 1)
  visited[targetStudent] = true
  queueHead = 0
  queueTail = 0
  traversalQueue[queueTail] = targetStudent
  queueTail += 1
  var ancestorCount = 0
  while queueHead < queueTail:
    let currentNode = traversalQueue[queueHead]
    queueHead += 1
    var edgeIndex = backwardHead[currentNode]
    while edgeIndex != -1:
      let neighbor = reverseDestination[edgeIndex]
      if not visited[neighbor]:
        visited[neighbor] = true
        ancestorCount += 1
        traversalQueue[queueTail] = neighbor
        queueTail += 1
      edgeIndex = reverseNext[edgeIndex]
  for nodeIndex in 1 .. studentCount:
    visited[nodeIndex] = false
  visited[targetStudent] = true
  queueHead = 0
  queueTail = 0
  traversalQueue[queueTail] = targetStudent
  queueTail += 1
  var descendantCount = 0
  while queueHead < queueTail:
    let currentNode = traversalQueue[queueHead]
    queueHead += 1
    var edgeIndex = forwardHead[currentNode]
    while edgeIndex != -1:
      let neighbor = edgeDestination[edgeIndex]
      if not visited[neighbor]:
        visited[neighbor] = true
        descendantCount += 1
        traversalQueue[queueTail] = neighbor
        queueTail += 1
      edgeIndex = edgeNext[edgeIndex]
  let lowestRank = ancestorCount + 1
  let highestRank = studentCount - descendantCount
  let possibleCount = highestRank - lowestRank + 1
  appendOutput($possibleCount)
  outputBuffer.add '\n'
  for rankValue in lowestRank .. highestRank:
    appendOutput($rankValue)
    if rankValue < highestRank:
      outputBuffer.add ' '
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

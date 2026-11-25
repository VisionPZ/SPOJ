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

proc hasNextNumber(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc greatestCommonDivisor(firstValue: int, secondValue: int): int =
  var larger = firstValue
  var smaller = secondValue
  while smaller != 0:
    let remainder = larger mod smaller
    larger = smaller
    smaller = remainder
  return larger

proc breadthFirst(leftCount: int, headLeft: seq[int], edgeTo: seq[int], edgeNext: seq[int],
                   pairLeft: seq[int], pairRight: seq[int], distance: var seq[int], queue: var seq[int]): bool =
  var queueHead = 0
  var queueTail = 0
  for leftNode in 0 .. leftCount - 1:
    if pairLeft[leftNode] == -1:
      distance[leftNode] = 0
      queue[queueTail] = leftNode
      queueTail += 1
    else:
      distance[leftNode] = -1
  var foundFreeRight = false
  while queueHead < queueTail:
    let leftNode = queue[queueHead]
    queueHead += 1
    var edgeLink = headLeft[leftNode]
    while edgeLink != -1:
      let rightNode = edgeTo[edgeLink]
      let matchedLeft = pairRight[rightNode]
      if matchedLeft == -1:
        foundFreeRight = true
      elif distance[matchedLeft] == -1:
        distance[matchedLeft] = distance[leftNode] + 1
        queue[queueTail] = matchedLeft
        queueTail += 1
      edgeLink = edgeNext[edgeLink]
  return foundFreeRight

proc depthFirstSearch(leftNode: int, headLeft: seq[int], edgeTo: seq[int], edgeNext: seq[int],
                      pairLeft: var seq[int], pairRight: var seq[int], distance: var seq[int]): bool =
  var edgeLink = headLeft[leftNode]
  while edgeLink != -1:
    let rightNode = edgeTo[edgeLink]
    let matchedLeft = pairRight[rightNode]
    if matchedLeft == -1:
      pairLeft[leftNode] = rightNode
      pairRight[rightNode] = leftNode
      return true
    if distance[matchedLeft] == distance[leftNode] + 1:
      if depthFirstSearch(matchedLeft, headLeft, edgeTo, edgeNext, pairLeft, pairRight, distance):
        pairLeft[leftNode] = rightNode
        pairRight[rightNode] = leftNode
        return true
    edgeLink = edgeNext[edgeLink]
  distance[leftNode] = -1
  return false

while hasNextNumber(inputData, scanPos):
  let leftCount = nextInt(inputData, scanPos)
  let rightCount = nextInt(inputData, scanPos)
  var leftKinds = newSeq[int](leftCount)
  var rightKinds = newSeq[int](rightCount)
  for leftIndex in 0 .. leftCount - 1:
    leftKinds[leftIndex] = nextInt(inputData, scanPos)
  for rightIndex in 0 .. rightCount - 1:
    rightKinds[rightIndex] = nextInt(inputData, scanPos)
  var headLeft = newSeq[int](leftCount)
  var edgeTo = newSeq[int](leftCount * rightCount)
  var edgeNext = newSeq[int](leftCount * rightCount)
  var edgeCount = 0
  for leftIndex in 0 .. leftCount - 1:
    headLeft[leftIndex] = -1
    for rightIndex in 0 .. rightCount - 1:
      if greatestCommonDivisor(leftKinds[leftIndex], rightKinds[rightIndex]) > 1:
        edgeTo[edgeCount] = rightIndex
        edgeNext[edgeCount] = headLeft[leftIndex]
        headLeft[leftIndex] = edgeCount
        edgeCount += 1
  var pairLeft = newSeq[int](leftCount)
  var pairRight = newSeq[int](rightCount)
  var distance = newSeq[int](leftCount)
  var queue = newSeq[int](leftCount)
  for leftIndex in 0 .. leftCount - 1:
    pairLeft[leftIndex] = -1
  for rightIndex in 0 .. rightCount - 1:
    pairRight[rightIndex] = -1
  var matching = 0
  while breadthFirst(leftCount, headLeft, edgeTo, edgeNext, pairLeft, pairRight, distance, queue):
    for leftIndex in 0 .. leftCount - 1:
      if pairLeft[leftIndex] == -1:
        if depthFirstSearch(leftIndex, headLeft, edgeTo, edgeNext, pairLeft, pairRight, distance):
          matching += 1
  appendOutput($(leftCount + rightCount - matching))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

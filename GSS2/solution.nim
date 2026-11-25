const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let elementCount = nextInt(inputData, scanPos)
var scores = newSeq[int](elementCount + 1)
for position in 1 .. elementCount:
  scores[position] = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
var firstAtRight = newSeq[int](elementCount + 2)
for position in 0 .. elementCount + 1:
  firstAtRight[position] = -1
var nextAtRight = newSeq[int](queryCount)
var leftEnds = newSeq[int](queryCount)
var answers = newSeq[int64](queryCount)
for queryIndex in 0 .. queryCount - 1:
  let leftEnd = nextInt(inputData, scanPos)
  let rightEnd = nextInt(inputData, scanPos)
  leftEnds[queryIndex] = leftEnd
  nextAtRight[queryIndex] = firstAtRight[rightEnd]
  firstAtRight[rightEnd] = queryIndex

const scoreOffset = 100000
var lastSeen = newSeq[int](2 * scoreOffset + 1)

var treeSum = newSeq[int64](4 * elementCount + 5)
var treeBest = newSeq[int64](4 * elementCount + 5)
var treeLazy = newSeq[int64](4 * elementCount + 5)
var treeBestLazy = newSeq[int64](4 * elementCount + 5)

proc pushDown(node: int, low: int, high: int) =
  if low == high:
    treeLazy[node] = 0
    treeBestLazy[node] = 0
    return
  let leftChild = node * 2
  let rightChild = node * 2 + 1
  treeBestLazy[leftChild] = max(treeBestLazy[leftChild], treeLazy[leftChild] + treeBestLazy[node])
  treeLazy[leftChild] = treeLazy[leftChild] + treeLazy[node]
  treeBest[leftChild] = max(treeBest[leftChild], treeSum[leftChild] + treeBestLazy[node])
  treeSum[leftChild] = treeSum[leftChild] + treeLazy[node]
  treeBestLazy[rightChild] = max(treeBestLazy[rightChild], treeLazy[rightChild] + treeBestLazy[node])
  treeLazy[rightChild] = treeLazy[rightChild] + treeLazy[node]
  treeBest[rightChild] = max(treeBest[rightChild], treeSum[rightChild] + treeBestLazy[node])
  treeSum[rightChild] = treeSum[rightChild] + treeLazy[node]
  treeLazy[node] = 0
  treeBestLazy[node] = 0

proc addRange(node: int, low: int, high: int, left: int, right: int, delta: int64) =
  if left <= low and high <= right:
    treeBestLazy[node] = max(treeBestLazy[node], treeLazy[node] + delta)
    treeLazy[node] = treeLazy[node] + delta
    treeBest[node] = max(treeBest[node], treeSum[node] + delta)
    treeSum[node] = treeSum[node] + delta
    return
  pushDown(node, low, high)
  let middle = (low + high) div 2
  if left <= middle:
    addRange(node * 2, low, middle, left, right, delta)
  if right > middle:
    addRange(node * 2 + 1, middle + 1, high, left, right, delta)
  treeBest[node] = max(treeBest[node * 2], treeBest[node * 2 + 1])
  treeSum[node] = max(treeSum[node * 2], treeSum[node * 2 + 1])

proc queryBest(node: int, low: int, high: int, left: int, right: int): int64 =
  if left <= low and high <= right:
    return treeBest[node]
  pushDown(node, low, high)
  let middle = (low + high) div 2
  if right <= middle:
    return queryBest(node * 2, low, middle, left, right)
  if left > middle:
    return queryBest(node * 2 + 1, middle + 1, high, left, right)
  let leftBest = queryBest(node * 2, low, middle, left, right)
  let rightBest = queryBest(node * 2 + 1, middle + 1, high, left, right)
  return max(leftBest, rightBest)

for rightPosition in 1 .. elementCount:
  let scoreIndex = scores[rightPosition] + scoreOffset
  let firstAffected = lastSeen[scoreIndex] + 1
  addRange(1, 1, elementCount, firstAffected, rightPosition, int64(scores[rightPosition]))
  lastSeen[scoreIndex] = rightPosition
  var queryIndex = firstAtRight[rightPosition]
  while queryIndex != -1:
    answers[queryIndex] = queryBest(1, 1, elementCount, leftEnds[queryIndex], rightPosition)
    queryIndex = nextAtRight[queryIndex]

for queryIndex in 0 .. queryCount - 1:
  appendOutput($answers[queryIndex])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

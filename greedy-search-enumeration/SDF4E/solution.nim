const flushBlockBytes = 1 shl 17
const infinity: int64 = 1 shl 60

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

proc heapPush(nodeHeap: var seq[int], keyHeap: var seq[int64], heapSize: var int, node: int, key: int64) =
  var child = heapSize
  heapSize += 1
  while child > 0:
    let parent = (child - 1) div 2
    if keyHeap[parent] <= key:
      break
    nodeHeap[child] = nodeHeap[parent]
    keyHeap[child] = keyHeap[parent]
    child = parent
  nodeHeap[child] = node
  keyHeap[child] = key

proc heapPop(nodeHeap: var seq[int], keyHeap: var seq[int64], heapSize: var int): tuple[key: int64, node: int] =
  let smallestKey = keyHeap[0]
  let smallestNode = nodeHeap[0]
  heapSize -= 1
  if heapSize > 0:
    let lastNode = nodeHeap[heapSize]
    let lastKey = keyHeap[heapSize]
    var parent = 0
    while true:
      let leftChild = 2 * parent + 1
      if leftChild >= heapSize:
        break
      let rightChild = leftChild + 1
      var smallerChild = leftChild
      if rightChild < heapSize and keyHeap[rightChild] < keyHeap[leftChild]:
        smallerChild = rightChild
      if lastKey <= keyHeap[smallerChild]:
        break
      nodeHeap[parent] = nodeHeap[smallerChild]
      keyHeap[parent] = keyHeap[smallerChild]
      parent = smallerChild
    nodeHeap[parent] = lastNode
    keyHeap[parent] = lastKey
  return (smallestKey, smallestNode)

proc computeDistances(nodeCount: int, head: seq[int], target: seq[int], weight: seq[int64], nextEdge: seq[int], capacity: int, source: int): seq[int64] =
  var distances = newSeq[int64](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    distances[nodeIndex] = infinity
  var nodeHeap = newSeq[int](capacity + 1)
  var keyHeap = newSeq[int64](capacity + 1)
  var heapSize = 0
  distances[source] = 0
  heapPush(nodeHeap, keyHeap, heapSize, source, 0)
  while heapSize > 0:
    let entry = heapPop(nodeHeap, keyHeap, heapSize)
    if entry.key != distances[entry.node]:
      continue
    var edgeIndex = head[entry.node]
    while edgeIndex != -1:
      let neighbour = target[edgeIndex]
      let candidate = entry.key + weight[edgeIndex]
      if candidate < distances[neighbour]:
        distances[neighbour] = candidate
        heapPush(nodeHeap, keyHeap, heapSize, neighbour, candidate)
      edgeIndex = nextEdge[edgeIndex]
  return distances

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let cityCount = nextInt(inputData, scanPos)
let roadCount = nextInt(inputData, scanPos)
let edgeCapacity = 2 * roadCount
var forwardHead = newSeq[int](cityCount)
var reverseHead = newSeq[int](cityCount)
for cityIndex in 0 .. cityCount - 1:
  forwardHead[cityIndex] = -1
  reverseHead[cityIndex] = -1
var forwardTarget = newSeq[int](edgeCapacity)
var reverseTarget = newSeq[int](edgeCapacity)
var forwardWeight = newSeq[int64](edgeCapacity)
var reverseWeight = newSeq[int64](edgeCapacity)
var forwardNext = newSeq[int](edgeCapacity)
var reverseNext = newSeq[int](edgeCapacity)
var edgeIndex = 0
for roadIndex in 0 .. roadCount - 1:
  let fromCity = nextInt(inputData, scanPos)
  let toCity = nextInt(inputData, scanPos)
  let roadLength = int64(nextInt(inputData, scanPos))
  forwardTarget[edgeIndex] = toCity
  forwardWeight[edgeIndex] = roadLength
  forwardNext[edgeIndex] = forwardHead[fromCity]
  forwardHead[fromCity] = edgeIndex
  reverseTarget[edgeIndex] = fromCity
  reverseWeight[edgeIndex] = roadLength
  reverseNext[edgeIndex] = reverseHead[toCity]
  reverseHead[toCity] = edgeIndex
  edgeIndex += 1
let fromStart = computeDistances(cityCount, forwardHead, forwardTarget, forwardWeight, forwardNext, edgeCapacity, 0)
let toFinish = computeDistances(cityCount, reverseHead, reverseTarget, reverseWeight, reverseNext, edgeCapacity, cityCount - 1)
let bestDistance = fromStart[cityCount - 1]
let queryCount = nextInt(inputData, scanPos)
for queryIndex in 0 .. queryCount - 1:
  let roadFrom = nextInt(inputData, scanPos)
  let roadTo = nextInt(inputData, scanPos)
  let roadCost = int64(nextInt(inputData, scanPos))
  if fromStart[roadFrom] < infinity and toFinish[roadTo] < infinity:
    let newDistance = fromStart[roadFrom] + roadCost + toFinish[roadTo]
    if newDistance < bestDistance:
      appendOutput("Boleh juga: " & $newDistance & " km")
      outputBuffer.add '\n'
      continue
  appendOutput("Tidaakkk...")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

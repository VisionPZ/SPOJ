const flushBlockBytes = 1 shl 17
const unreachableTime = 1 shl 29

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

proc heapPush(heap: var seq[int], encodedValue: int) =
  heap.add encodedValue
  var childIndex = heap.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heap[parentIndex] <= heap[childIndex]:
      break
    let parentValue = heap[parentIndex]
    heap[parentIndex] = heap[childIndex]
    heap[childIndex] = parentValue
    childIndex = parentIndex

proc heapPop(heap: var seq[int]): int =
  let smallestValue = heap[0]
  let lastValue = heap[heap.len - 1]
  heap.setLen(heap.len - 1)
  if heap.len > 0:
    heap[0] = lastValue
    var parentIndex = 0
    while true:
      let leftIndex = 2 * parentIndex + 1
      if leftIndex >= heap.len:
        break
      let rightIndex = leftIndex + 1
      var smallerIndex = leftIndex
      if rightIndex < heap.len and heap[rightIndex] < heap[leftIndex]:
        smallerIndex = rightIndex
      if heap[parentIndex] <= heap[smallerIndex]:
        break
      let parentValue = heap[parentIndex]
      heap[parentIndex] = heap[smallerIndex]
      heap[smallerIndex] = parentValue
      parentIndex = smallerIndex
  return smallestValue

proc shortestTime(rows: int, cols: int, guardTimes: seq[int], targetIndex: int): int =
  let nodeCount = rows * cols
  var distances = newSeq[int](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    distances[nodeIndex] = unreachableTime
  var heap = newSeq[int]()
  let startEncoded = guardTimes[0] * nodeCount
  distances[0] = guardTimes[0]
  heapPush(heap, startEncoded)
  let deltaRows = [-1, 1, 0, 0]
  let deltaCols = [0, 0, -1, 1]
  while heap.len > 0:
    let encodedValue = heapPop(heap)
    let nodeIndex = encodedValue mod nodeCount
    let arrivalTime = encodedValue div nodeCount
    if arrivalTime != distances[nodeIndex]:
      continue
    if nodeIndex == targetIndex:
      break
    let currentRow = nodeIndex div cols
    let currentCol = nodeIndex mod cols
    for directionIndex in 0 .. 3:
      let nextRow = currentRow + deltaRows[directionIndex]
      let nextCol = currentCol + deltaCols[directionIndex]
      if nextRow < 0 or nextRow >= rows or nextCol < 0 or nextCol >= cols:
        continue
      let nextIndex = nextRow * cols + nextCol
      let nextTime = arrivalTime + guardTimes[nextIndex]
      if nextTime < distances[nextIndex]:
        distances[nextIndex] = nextTime
        heapPush(heap, nextTime * nodeCount + nextIndex)
  return distances[targetIndex]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rows = nextInt(inputData, scanPos)
  let cols = nextInt(inputData, scanPos)
  var guardTimes = newSeq[int](rows * cols)
  for cellIndex in 0 .. rows * cols - 1:
    guardTimes[cellIndex] = nextInt(inputData, scanPos)
  let targetRow = nextInt(inputData, scanPos) - 1
  let targetCol = nextInt(inputData, scanPos) - 1
  let bombTime = nextInt(inputData, scanPos)
  let targetIndex = targetRow * cols + targetCol
  let neededTime = shortestTime(rows, cols, guardTimes, targetIndex)
  if neededTime <= bombTime:
    appendOutput("YES\n")
    appendOutput($(bombTime - neededTime))
    outputBuffer.add '\n'
  else:
    appendOutput("NO\n")

stdout.write outputBuffer
outputBuffer.setLen 0

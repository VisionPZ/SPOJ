const flushBlockBytes = 1 shl 17
const largeDistance = int64(1000000000000000000)

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

let buildingHeight = int64(nextInt(inputData, scanPos))
var buttonSteps = newSeq[int](3)
for buttonIndex in 0 .. 2:
  buttonSteps[buttonIndex] = nextInt(inputData, scanPos)
var shortestSteps = buttonSteps[0]
for buttonIndex in 1 .. 2:
  if buttonSteps[buttonIndex] < shortestSteps:
    shortestSteps = buttonSteps[buttonIndex]

var residueDistances = newSeq[int64](shortestSteps)
for residue in 0 .. shortestSteps - 1:
  residueDistances[residue] = largeDistance
residueDistances[0] = 0

var heapPriorities = newSeq[int64]()
var heapNodes = newSeq[int]()

proc heapPush(priority: int64, node: int) =
  heapPriorities.add priority
  heapNodes.add node
  var childIndex = heapPriorities.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heapPriorities[parentIndex] <= heapPriorities[childIndex]:
      break
    swap(heapPriorities[parentIndex], heapPriorities[childIndex])
    swap(heapNodes[parentIndex], heapNodes[childIndex])
    childIndex = parentIndex

proc heapPop(): tuple[priority: int64, node: int] =
  result.priority = heapPriorities[0]
  result.node = heapNodes[0]
  let lastPriority = heapPriorities[heapPriorities.len - 1]
  let lastNode = heapNodes[heapNodes.len - 1]
  heapPriorities.setLen(heapPriorities.len - 1)
  heapNodes.setLen(heapNodes.len - 1)
  if heapPriorities.len > 0:
    heapPriorities[0] = lastPriority
    heapNodes[0] = lastNode
    var parentIndex = 0
    while true:
      let leftChild = 2 * parentIndex + 1
      if leftChild >= heapPriorities.len:
        break
      let rightChild = leftChild + 1
      var smallerChild = leftChild
      if rightChild < heapPriorities.len and heapPriorities[rightChild] < heapPriorities[leftChild]:
        smallerChild = rightChild
      if heapPriorities[parentIndex] <= heapPriorities[smallerChild]:
        break
      swap(heapPriorities[parentIndex], heapPriorities[smallerChild])
      swap(heapNodes[parentIndex], heapNodes[smallerChild])
      parentIndex = smallerChild

heapPush(0, 0)
while heapNodes.len > 0:
  let entry = heapPop()
  if entry.priority > residueDistances[entry.node]:
    continue
  for buttonIndex in 0 .. 2:
    let buttonStep = buttonSteps[buttonIndex]
    if buttonStep == shortestSteps:
      continue
    let nextResidue = (entry.node + buttonStep) mod shortestSteps
    let nextDistance = entry.priority + int64(buttonStep)
    if nextDistance < residueDistances[nextResidue]:
      residueDistances[nextResidue] = nextDistance
      heapPush(nextDistance, nextResidue)

let highestOffset = buildingHeight - 1
var reachableFloors: int64 = 0
for residue in 0 .. shortestSteps - 1:
  if residueDistances[residue] <= highestOffset:
    reachableFloors += (highestOffset - residueDistances[residue]) div int64(shortestSteps) + 1
appendOutput($reachableFloors)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

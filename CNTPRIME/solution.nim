const flushBlockBytes = 1 shl 17
const maxNumber = 1000000
const sieveRoot = 1000
const noPendingValue = -1

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

var isPrimeValue = newSeq[bool](maxNumber + 1)
var initialValues: seq[int] = @[]
var primeCounts: seq[int] = @[]
var pendingValues: seq[int] = @[]

var sieveFactor = 2
while sieveFactor <= maxNumber:
  isPrimeValue[sieveFactor] = true
  sieveFactor += 1
sieveFactor = 2
while sieveFactor <= sieveRoot:
  if isPrimeValue[sieveFactor]:
    var multiple = sieveFactor * sieveFactor
    while multiple <= maxNumber:
      isPrimeValue[multiple] = false
      multiple += sieveFactor
  sieveFactor += 1

proc applyValue(nodeIndex: int, leftBound: int, rightBound: int, assignedValue: int) =
  if isPrimeValue[assignedValue]:
    primeCounts[nodeIndex] = rightBound - leftBound + 1
  else:
    primeCounts[nodeIndex] = 0
  pendingValues[nodeIndex] = assignedValue

proc pushPending(nodeIndex: int, leftBound: int, rightBound: int) =
  if pendingValues[nodeIndex] != noPendingValue and leftBound != rightBound:
    let middle = (leftBound + rightBound) div 2
    applyValue(nodeIndex * 2, leftBound, middle, pendingValues[nodeIndex])
    applyValue(nodeIndex * 2 + 1, middle + 1, rightBound, pendingValues[nodeIndex])
    pendingValues[nodeIndex] = noPendingValue

proc pullCounts(nodeIndex: int) =
  primeCounts[nodeIndex] = primeCounts[nodeIndex * 2] + primeCounts[nodeIndex * 2 + 1]

proc buildTree(nodeIndex: int, leftBound: int, rightBound: int) =
  if leftBound == rightBound:
    if isPrimeValue[initialValues[leftBound]]:
      primeCounts[nodeIndex] = 1
    else:
      primeCounts[nodeIndex] = 0
    return
  let middle = (leftBound + rightBound) div 2
  buildTree(nodeIndex * 2, leftBound, middle)
  buildTree(nodeIndex * 2 + 1, middle + 1, rightBound)
  pullCounts(nodeIndex)

proc updateRange(nodeIndex: int, leftBound: int, rightBound: int,
                 queryLeft: int, queryRight: int, assignedValue: int) =
  if queryLeft <= leftBound and rightBound <= queryRight:
    applyValue(nodeIndex, leftBound, rightBound, assignedValue)
    return
  pushPending(nodeIndex, leftBound, rightBound)
  let middle = (leftBound + rightBound) div 2
  if queryLeft <= middle:
    updateRange(nodeIndex * 2, leftBound, middle, queryLeft, queryRight, assignedValue)
  if queryRight > middle:
    updateRange(nodeIndex * 2 + 1, middle + 1, rightBound, queryLeft, queryRight, assignedValue)
  pullCounts(nodeIndex)

proc queryRange(nodeIndex: int, leftBound: int, rightBound: int,
                queryLeft: int, queryRight: int): int =
  if queryLeft <= leftBound and rightBound <= queryRight:
    return primeCounts[nodeIndex]
  pushPending(nodeIndex, leftBound, rightBound)
  let middle = (leftBound + rightBound) div 2
  var total = 0
  if queryLeft <= middle:
    total += queryRange(nodeIndex * 2, leftBound, middle, queryLeft, queryRight)
  if queryRight > middle:
    total += queryRange(nodeIndex * 2 + 1, middle + 1, rightBound, queryLeft, queryRight)
  return total

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let elementCount = nextInt(inputData, scanPos)
  let commandCount = nextInt(inputData, scanPos)
  initialValues = newSeq[int](elementCount + 1)
  for elementIndex in 1 .. elementCount:
    initialValues[elementIndex] = nextInt(inputData, scanPos)
  let treeSize = 4 * elementCount + 5
  primeCounts = newSeq[int](treeSize)
  pendingValues = newSeq[int](treeSize)
  for nodeIndex in 0 .. treeSize - 1:
    pendingValues[nodeIndex] = noPendingValue
  buildTree(1, 1, elementCount)
  appendOutput("Case " & $caseIndex & ":\n")
  for commandIndex in 1 .. commandCount:
    let commandType = nextInt(inputData, scanPos)
    if commandType == 0:
      let rangeLeft = nextInt(inputData, scanPos)
      let rangeRight = nextInt(inputData, scanPos)
      let assignedValue = nextInt(inputData, scanPos)
      updateRange(1, 1, elementCount, rangeLeft, rangeRight, assignedValue)
    else:
      let rangeLeft = nextInt(inputData, scanPos)
      let rangeRight = nextInt(inputData, scanPos)
      appendOutput($queryRange(1, 1, elementCount, rangeLeft, rangeRight))
      outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

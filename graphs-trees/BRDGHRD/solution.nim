import algorithm

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
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc comparePairs(left: tuple[firstValue: int, secondValue: int], right: tuple[firstValue: int, secondValue: int]): int =
  if left.firstValue < right.firstValue:
    return -1
  if left.firstValue > right.firstValue:
    return 1
  if left.secondValue < right.secondValue:
    return -1
  if left.secondValue > right.secondValue:
    return 1
  return 0

proc upperPosition(values: seq[int], target: int): int =
  var low = 0
  var high = values.len
  while low < high:
    let middle = (low + high) div 2
    if values[middle] <= target:
      low = middle + 1
    else:
      high = middle
  return low

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let endpointCount = nextInt(inputData, scanPos)
  var firstCoordinates = newSeq[int](endpointCount)
  var secondCoordinates = newSeq[int](endpointCount)
  for endpointIndex in 0 .. endpointCount - 1:
    firstCoordinates[endpointIndex] = nextInt(inputData, scanPos)
  for endpointIndex in 0 .. endpointCount - 1:
    secondCoordinates[endpointIndex] = nextInt(inputData, scanPos)
  var endpointPairs = newSeq[tuple[firstValue: int, secondValue: int]](endpointCount)
  for endpointIndex in 0 .. endpointCount - 1:
    endpointPairs[endpointIndex] = (firstCoordinates[endpointIndex], secondCoordinates[endpointIndex])
  endpointPairs.sort(comparePairs)
  var tailValues = newSeq[int]()
  for pairIndex in 0 .. endpointCount - 1:
    let currentValue = endpointPairs[pairIndex].secondValue
    let insertAt = upperPosition(tailValues, currentValue)
    if insertAt == tailValues.len:
      tailValues.add currentValue
    else:
      tailValues[insertAt] = currentValue
  appendOutput($tailValues.len)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

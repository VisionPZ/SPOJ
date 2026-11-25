import algorithm

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

proc ascending(left: int, right: int): int =
  if left < right:
    return -1
  if left > right:
    return 1
  return 0

let caseCount = nextInt(inputData, scanPos)
var caseIndex = 1
while caseIndex <= caseCount:
  let arraySize = nextInt(inputData, scanPos)
  var values = newSeq[int](arraySize)
  var valueIndex = 0
  while valueIndex < arraySize:
    values[valueIndex] = nextInt(inputData, scanPos)
    valueIndex += 1
  let targetSum = int64(nextInt(inputData, scanPos))
  values.sort(ascending)
  var foundTriple = false
  var firstIndex = 0
  while firstIndex < arraySize - 2 and not foundTriple:
    var leftIndex = firstIndex + 1
    var rightIndex = arraySize - 1
    while leftIndex < rightIndex and not foundTriple:
      let threeSum = int64(values[firstIndex]) + int64(values[leftIndex]) + int64(values[rightIndex])
      if threeSum == targetSum:
        foundTriple = true
      elif threeSum < targetSum:
        leftIndex += 1
      else:
        rightIndex -= 1
    firstIndex += 1
  if foundTriple:
    appendOutput("YES")
  else:
    appendOutput("NO")
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0

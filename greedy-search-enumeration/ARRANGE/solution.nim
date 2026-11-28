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

proc sortFactors(values: var seq[int], lowIndex: int, highIndex: int) =
  if lowIndex >= highIndex:
    return
  let pivotValue = values[(lowIndex + highIndex) div 2]
  var leftIndex = lowIndex
  var rightIndex = highIndex
  while leftIndex <= rightIndex:
    while values[leftIndex] > pivotValue:
      leftIndex += 1
    while values[rightIndex] < pivotValue:
      rightIndex -= 1
    if leftIndex <= rightIndex:
      swap values[leftIndex], values[rightIndex]
      leftIndex += 1
      rightIndex -= 1
  sortFactors(values, lowIndex, rightIndex)
  sortFactors(values, leftIndex, highIndex)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let amplifierCount = nextInt(inputData, scanPos)
  var onesSeen = 0
  var largeFactors = newSeq[int](0)
  for amplifierIndex in 0 .. amplifierCount - 1:
    let factor = nextInt(inputData, scanPos)
    if factor == 1:
      onesSeen += 1
    else:
      largeFactors.add factor
  sortFactors(largeFactors, 0, largeFactors.len - 1)
  if largeFactors.len >= 2 and largeFactors[0] == 3 and largeFactors[1] == 2:
    largeFactors[0] = 2
    largeFactors[1] = 3
  var printedAny = false
  for oneIndex in 0 .. onesSeen - 1:
    if printedAny:
      outputBuffer.add ' '
    appendOutput("1")
    printedAny = true
  for factorIndex in 0 .. largeFactors.len - 1:
    if printedAny:
      outputBuffer.add ' '
    appendOutput($largeFactors[factorIndex])
    printedAny = true
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

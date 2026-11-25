const flushBlockBytes = 1 shl 17
const resultModulo = 1000000007

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

proc multiplyModulo(firstValue: int64, secondValue: int64, modulusValue: int64): int64 =
  {.emit: """
  __int128 product = (__int128)`firstValue` * (__int128)`secondValue`;
  `result` = (NI64)(product % `modulusValue`);
  """.}

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let fieldSize = nextInt(inputData, scanPos)
let windowSize = nextInt(inputData, scanPos)
let windowCount = fieldSize - windowSize + 1
var rowMinimums = newSeq[int64](fieldSize * windowCount)
var generatedValues = newSeq[int64](fieldSize)
var windowQueue = newSeq[int](fieldSize)

for rowIndex in 0 .. fieldSize - 1:
  let initialValue = int64(nextInt(inputData, scanPos))
  let multiplierValue = int64(nextInt(inputData, scanPos))
  let addendValue = int64(nextInt(inputData, scanPos))
  let modulusValue = int64(nextInt(inputData, scanPos))
  var currentValue = initialValue
  for columnIndex in 0 .. fieldSize - 1:
    generatedValues[columnIndex] = currentValue
    currentValue = (multiplyModulo(currentValue, multiplierValue, modulusValue) + addendValue) mod modulusValue
  var queueHead = 0
  var queueTail = 0
  for columnIndex in 0 .. fieldSize - 1:
    while queueTail > queueHead and generatedValues[windowQueue[queueTail - 1]] >= generatedValues[columnIndex]:
      queueTail -= 1
    windowQueue[queueTail] = columnIndex
    queueTail += 1
    while windowQueue[queueHead] <= columnIndex - windowSize:
      queueHead += 1
    if columnIndex >= windowSize - 1:
      rowMinimums[rowIndex * windowCount + columnIndex - windowSize + 1] = generatedValues[windowQueue[queueHead]]

var totalMinimums: int64 = 0
for columnIndex in 0 .. windowCount - 1:
  var queueHead = 0
  var queueTail = 0
  for rowIndex in 0 .. fieldSize - 1:
    let currentValue = rowMinimums[rowIndex * windowCount + columnIndex]
    while queueTail > queueHead and rowMinimums[windowQueue[queueTail - 1] * windowCount + columnIndex] >= currentValue:
      queueTail -= 1
    windowQueue[queueTail] = rowIndex
    queueTail += 1
    while windowQueue[queueHead] <= rowIndex - windowSize:
      queueHead += 1
    if rowIndex >= windowSize - 1:
      totalMinimums = (totalMinimums + rowMinimums[windowQueue[queueHead] * windowCount + columnIndex]) mod resultModulo

appendOutput($totalMinimums)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

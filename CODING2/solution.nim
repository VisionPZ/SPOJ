const flushBlockBytes = 1 shl 17
const numberBase = 10

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
    value = value * numberBase + int(data[pos]) - 48
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var heapValues = newSeq[int64]()

proc heapPush(value: int64) =
  heapValues.add value
  var childIndex = heapValues.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heapValues[parentIndex] <= heapValues[childIndex]:
      break
    let heldValue = heapValues[parentIndex]
    heapValues[parentIndex] = heapValues[childIndex]
    heapValues[childIndex] = heldValue
    childIndex = parentIndex

proc heapPop(): int64 =
  result = heapValues[0]
  let lastValue = heapValues[heapValues.len - 1]
  heapValues.setLen(heapValues.len - 1)
  if heapValues.len > 0:
    heapValues[0] = lastValue
    var parentIndex = 0
    while true:
      let leftIndex = parentIndex * 2 + 1
      if leftIndex >= heapValues.len:
        break
      let rightIndex = leftIndex + 1
      var smallerIndex = leftIndex
      if rightIndex < heapValues.len and heapValues[rightIndex] < heapValues[leftIndex]:
        smallerIndex = rightIndex
      if heapValues[parentIndex] <= heapValues[smallerIndex]:
        break
      let heldValue = heapValues[parentIndex]
      heapValues[parentIndex] = heapValues[smallerIndex]
      heapValues[smallerIndex] = heldValue
      parentIndex = smallerIndex

while true:
  let alphabetBits = nextInt(inputData, scanPos)
  let messageLength = nextInt(inputData, scanPos)
  if alphabetBits == 0 and messageLength == 0:
    break
  let alphabetSize = 1 shl alphabetBits
  var symbolCounts = newSeq[int](alphabetSize)
  for symbolIndex in 0 .. alphabetSize - 1:
    symbolCounts[symbolIndex] = 0
  for messageIndex in 0 .. messageLength - 1:
    let symbolValue = nextInt(inputData, scanPos)
    symbolCounts[symbolValue] += 1
  heapValues.setLen 0
  var usedSymbols = 0
  for symbolIndex in 0 .. alphabetSize - 1:
    if symbolCounts[symbolIndex] > 0:
      heapPush(int64(symbolCounts[symbolIndex]))
      usedSymbols += 1
  var totalBits: int64 = 0
  if usedSymbols == 1:
    totalBits = heapValues[0]
  else:
    while heapValues.len > 1:
      let firstWeight = heapPop()
      let secondWeight = heapPop()
      let combinedWeight = firstWeight + secondWeight
      totalBits = totalBits + combinedWeight
      heapPush(combinedWeight)
  appendOutput($totalBits)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

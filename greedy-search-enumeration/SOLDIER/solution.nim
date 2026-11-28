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

let itemCount = nextInt(inputData, scanPos)
let budgetLimit = nextInt(inputData, scanPos)
var itemTypes = newSeq[int](itemCount)
var itemPrices = newSeq[int](itemCount)
var itemQualities = newSeq[int](itemCount)
for itemIndex in 0 .. itemCount - 1:
  itemTypes[itemIndex] = nextInt(inputData, scanPos)
  itemPrices[itemIndex] = nextInt(inputData, scanPos)
  itemQualities[itemIndex] = nextInt(inputData, scanPos)

var bestQuality = 0
var candidateQuality = budgetLimit - 1
while candidateQuality >= 1 and bestQuality == 0:
  var minimumPrices = newSeq[int](7)
  for typeIndex in 0 .. 6:
    minimumPrices[typeIndex] = high(int)
  for itemIndex in 0 .. itemCount - 1:
    let equipmentType = itemTypes[itemIndex]
    if itemQualities[itemIndex] >= candidateQuality and equipmentType >= 1 and equipmentType <= 6:
      if itemPrices[itemIndex] < minimumPrices[equipmentType]:
        minimumPrices[equipmentType] = itemPrices[itemIndex]
  var totalPrice = 0
  var allTypesAvailable = true
  for equipmentType in 1 .. 6:
    if minimumPrices[equipmentType] == high(int):
      allTypesAvailable = false
    else:
      totalPrice += minimumPrices[equipmentType]
  if allTypesAvailable and totalPrice <= budgetLimit:
    bestQuality = candidateQuality
  candidateQuality -= 1

appendOutput($bestQuality)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

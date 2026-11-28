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

let pigCount = nextInt(inputData, scanPos)
let fuelCost = int64(nextInt(inputData, scanPos))
var pigWeights = newSeq[int](pigCount)
var pigNumbers = newSeq[int](pigCount)
for pigIndex in 0 .. pigCount - 1:
  pigWeights[pigIndex] = nextInt(inputData, scanPos)
  pigNumbers[pigIndex] = pigIndex + 1
var villageDistances = newSeq[int64](pigCount)
for villageIndex in 0 .. pigCount - 1:
  villageDistances[villageIndex] = int64(nextInt(inputData, scanPos))
var villagePrices = newSeq[int64](pigCount)
for villageIndex in 0 .. pigCount - 1:
  villagePrices[villageIndex] = int64(nextInt(inputData, scanPos))
var villageValues = newSeq[int64](pigCount)
var villageNumbers = newSeq[int](pigCount)
for villageIndex in 0 .. pigCount - 1:
  villageValues[villageIndex] = villagePrices[villageIndex] - fuelCost * villageDistances[villageIndex]
  villageNumbers[villageIndex] = villageIndex + 1

for sortIndex in 1 .. pigCount - 1:
  var insertionIndex = sortIndex
  while insertionIndex > 0 and pigWeights[insertionIndex - 1] > pigWeights[insertionIndex]:
    let weightSwap = pigWeights[insertionIndex - 1]
    pigWeights[insertionIndex - 1] = pigWeights[insertionIndex]
    pigWeights[insertionIndex] = weightSwap
    let numberSwap = pigNumbers[insertionIndex - 1]
    pigNumbers[insertionIndex - 1] = pigNumbers[insertionIndex]
    pigNumbers[insertionIndex] = numberSwap
    insertionIndex -= 1

for sortIndex in 1 .. pigCount - 1:
  var insertionIndex = sortIndex
  while insertionIndex > 0 and villageValues[insertionIndex - 1] > villageValues[insertionIndex]:
    let valueSwap = villageValues[insertionIndex - 1]
    villageValues[insertionIndex - 1] = villageValues[insertionIndex]
    villageValues[insertionIndex] = valueSwap
    let numberSwap = villageNumbers[insertionIndex - 1]
    villageNumbers[insertionIndex - 1] = villageNumbers[insertionIndex]
    villageNumbers[insertionIndex] = numberSwap
    insertionIndex -= 1

var chosenPigNumbers = newSeq[int](pigCount)
for pairIndex in 0 .. pigCount - 1:
  chosenPigNumbers[villageNumbers[pairIndex] - 1] = pigNumbers[pairIndex]
for villageIndex in 0 .. pigCount - 1:
  if villageIndex > 0:
    outputBuffer.add ' '
  appendOutput($chosenPigNumbers[villageIndex])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

import math

const flushBlockBytes = 1 shl 17
const infinityLength = 1e100
const digitsPerGroup = 3

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

proc formatRupiah(value: int64): string =
  let digitText = $value
  let groupCount = (digitText.len - 1) div digitsPerGroup
  result = newStringOfCap(digitText.len + groupCount)
  for digitIndex in 0 .. digitText.len - 1:
    if digitIndex > 0 and (digitText.len - digitIndex) mod digitsPerGroup == 0:
      result.add '.'
    result.add digitText[digitIndex]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let plantCount = nextInt(inputData, scanPos)
  let pricePerMeter = nextInt(inputData, scanPos)
  var plantXs = newSeq[int](plantCount)
  var plantYs = newSeq[int](plantCount)
  for plantIndex in 0 .. plantCount - 1:
    plantXs[plantIndex] = nextInt(inputData, scanPos)
    plantYs[plantIndex] = nextInt(inputData, scanPos)
  var closestEdges = newSeq[float](plantCount)
  var linkedPlants = newSeq[bool](plantCount)
  for plantIndex in 0 .. plantCount - 1:
    closestEdges[plantIndex] = infinityLength
  closestEdges[0] = 0.0
  var totalLength = 0.0
  for stepIndex in 0 .. plantCount - 1:
    var chosenPlant = -1
    var chosenLength = infinityLength
    for plantIndex in 0 .. plantCount - 1:
      if not linkedPlants[plantIndex] and closestEdges[plantIndex] < chosenLength:
        chosenLength = closestEdges[plantIndex]
        chosenPlant = plantIndex
    linkedPlants[chosenPlant] = true
    totalLength = totalLength + chosenLength
    for plantIndex in 0 .. plantCount - 1:
      if not linkedPlants[plantIndex]:
        let horizontalGap = float(plantXs[chosenPlant] - plantXs[plantIndex])
        let verticalGap = float(plantYs[chosenPlant] - plantYs[plantIndex])
        let edgeLength = sqrt(horizontalGap * horizontalGap + verticalGap * verticalGap)
        if edgeLength < closestEdges[plantIndex]:
          closestEdges[plantIndex] = edgeLength
  let rawCost = totalLength * float(pricePerMeter)
  let roundedCost = int64(ceil(rawCost - 1e-9))
  appendOutput("Rp " & formatRupiah(roundedCost))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

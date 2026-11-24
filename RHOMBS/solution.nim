const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const directionNorthWest = 1
const directionNorthEast = 2
const directionEast = 3
const directionSouthEast = 4
const directionSouthWest = 5
const directionWest = 6

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  let sideCount = nextInt(inputData, i)
  var latticeX: int64 = 0
  var latticeY: int64 = 0
  var doubleArea: int64 = 0
  var totalRhombsA: int64 = 0
  var totalRhombsC: int64 = 0
  for k in 0..<sideCount:
    let direction = nextInt(inputData, i)
    let sideLength = int64(nextInt(inputData, i))
    var nextX = latticeX
    var nextY = latticeY
    case direction
    of directionNorthWest:
      nextX = latticeX + sideLength
      totalRhombsC += sideLength * latticeX + sideLength * (sideLength - 1) div 2
    of directionNorthEast:
      nextY = latticeY + sideLength
      totalRhombsA -= sideLength * latticeY + sideLength * (sideLength - 1) div 2
    of directionEast:
      nextX = latticeX - sideLength
      nextY = latticeY + sideLength
    of directionSouthEast:
      nextX = latticeX - sideLength
      totalRhombsC += sideLength * (sideLength + 1) div 2 - sideLength * latticeX
    of directionSouthWest:
      nextY = latticeY - sideLength
      totalRhombsA += sideLength * latticeY - sideLength * (sideLength + 1) div 2
    of directionWest:
      nextX = latticeX + sideLength
      nextY = latticeY - sideLength
    else:
      discard
    doubleArea += latticeX * nextY - nextX * latticeY
    latticeX = nextX
    latticeY = nextY
  let totalRhombsB = doubleArea div 2 - totalRhombsA - totalRhombsC
  appendOutput($(totalRhombsA) & " " & $(totalRhombsB) & " " & $(totalRhombsC))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const moduloValue: int64 = 12345678

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

proc modPower(baseValue: int64, exponentValue: int64): int64 =
  var resultValue: int64 = 1
  var baseMod = baseValue mod moduloValue
  var exponentLeft = exponentValue
  while exponentLeft > 0:
    if exponentLeft mod 2 == 1:
      resultValue = (resultValue * baseMod) mod moduloValue
    baseMod = (baseMod * baseMod) mod moduloValue
    exponentLeft = exponentLeft div 2
  return resultValue

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let levelCount = int64(nextInt(inputData, scanPos))
  let settlementCount = int64(nextInt(inputData, scanPos))
  let stopCount = int64(nextInt(inputData, scanPos))
  var ringMoves: int64 = 2
  if settlementCount <= 2:
    ringMoves = 1
  var levelNeighbors: int64 = 2
  if levelCount == 1:
    levelNeighbors = 0
  elif levelCount == 2:
    levelNeighbors = 1
  let baseMoves = (ringMoves + levelNeighbors * settlementCount) mod moduloValue
  let crossings = stopCount - 1
  let startingPlaces = ((levelCount mod moduloValue) * (settlementCount mod moduloValue)) mod moduloValue
  let routeCount = (startingPlaces * modPower(baseMoves, crossings)) mod moduloValue
  appendOutput($routeCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

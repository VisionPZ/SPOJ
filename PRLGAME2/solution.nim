const flushBlockBytes = 1 shl 17
const decimalPlaces = 10000

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

proc hasMoreTokens(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len:
    if data[cursor] >= '0' and data[cursor] <= '9':
      return true
    cursor += 1
  return false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendFixedProbability(redDraws: int64, totalDraws: int64) =
  let scaledValue = (2 * (redDraws + 1) * decimalPlaces + totalDraws + 2) div
                    (2 * (totalDraws + 2))
  let wholePart = scaledValue div decimalPlaces
  let fractionPart = scaledValue mod decimalPlaces
  appendOutput($wholePart)
  outputBuffer.add '.'
  var digitWeight: int64 = decimalPlaces div 10
  while digitWeight > 0:
    let digitValue = (fractionPart div digitWeight) mod 10
    outputBuffer.add chr(48 + int(digitValue))
    digitWeight = digitWeight div 10

var caseNumber = 1
while hasMoreTokens(inputData, scanPos):
  discard nextInt(inputData, scanPos)
  let drawnCount = int64(nextInt(inputData, scanPos))
  let redCount = int64(nextInt(inputData, scanPos))
  appendOutput("Case " & $caseNumber & ": ")
  appendFixedProbability(redCount, drawnCount)
  outputBuffer.add '\n'
  caseNumber += 1

stdout.write outputBuffer
outputBuffer.setLen 0

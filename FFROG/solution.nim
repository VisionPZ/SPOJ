const flushBlockBytes = 1 shl 17
const sensibleMessage = "SensibleFrog Wins!."
const smartMessage = "SmartFrog Wins!."

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

proc countModulo(token: string, modulusValue: int64): int64 =
  var remainder: int64 = 0
  for charIndex in 0 .. token.len - 1:
    remainder = (remainder * 10 + int64(int(token[charIndex]) - 48)) mod modulusValue
  return remainder

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let moveLimit = nextInt(inputData, scanPos)
  let modulusValue = int64(moveLimit) + 1
  var rowHeaps = newSeq[int64](rowCount)
  var columnHeaps = newSeq[int64](columnCount)
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. columnCount - 1:
      let frogToken = nextToken(inputData, scanPos)
      let frogCount = countModulo(frogToken, modulusValue)
      rowHeaps[rowIndex] = (rowHeaps[rowIndex] + frogCount) mod modulusValue
      columnHeaps[columnIndex] = (columnHeaps[columnIndex] + frogCount) mod modulusValue
  var firstPlayerWins = false
  var digitWeight: int64 = 1
  let maximumCoordinate = max(rowCount, columnCount) - 1
  while digitWeight <= int64(maximumCoordinate):
    var digitTotal: int64 = 0
    for rowIndex in 0 .. rowCount - 1:
      let digitValue = (int64(rowIndex) div digitWeight) mod 2
      digitTotal += rowHeaps[rowIndex] * digitValue
      digitTotal = digitTotal mod modulusValue
    for columnIndex in 0 .. columnCount - 1:
      let digitValue = (int64(columnIndex) div digitWeight) mod 2
      digitTotal += columnHeaps[columnIndex] * digitValue
      digitTotal = digitTotal mod modulusValue
    if digitTotal mod modulusValue != 0:
      firstPlayerWins = true
    if digitWeight > int64(maximumCoordinate) div 2:
      break
    digitWeight *= 2
  if firstPlayerWins:
    appendOutput(sensibleMessage)
  else:
    appendOutput(smartMessage)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

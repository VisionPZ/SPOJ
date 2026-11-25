const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var tokenValue = ""
  while pos < data.len and data[pos] > ' ':
    tokenValue.add data[pos]
    pos += 1
  return tokenValue

proc nextCents(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var wholePart: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    wholePart = wholePart * 10 + int64(data[pos]) - firstDigitValue
    pos += 1
  var centValue = wholePart * 100
  if pos < data.len and data[pos] == '.':
    pos += 1
    var digitCount = 0
    var fractionValue: int64 = 0
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9' and digitCount < 2:
      fractionValue = fractionValue * 10 + int64(data[pos]) - firstDigitValue
      pos += 1
      digitCount += 1
    if digitCount == 1:
      fractionValue *= 10
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      pos += 1
    centValue += fractionValue
  return centValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendMoney(cents: int64) =
  appendOutput($(cents div 100))
  outputBuffer.add '.'
  let fractionPart = cents mod 100
  if fractionPart < 10:
    outputBuffer.add '0'
  appendOutput($(fractionPart))

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let itemCount = nextInt(inputData, scanPos)
  var totalWithGst: int64 = 0
  var totalGst: int64 = 0
  for itemIndex in 0 ..< itemCount:
    discard nextToken(inputData, scanPos)
    let quantity = int64(nextInt(inputData, scanPos))
    let priceCents = nextCents(inputData, scanPos)
    let rateToken = nextToken(inputData, scanPos)
    let subtotalCents = quantity * priceCents
    if rateToken == "SR":
      let includedCents = (subtotalCents * 106 + 50) div 100
      totalWithGst += includedCents
      totalGst += includedCents - subtotalCents
    else:
      totalWithGst += subtotalCents
  appendOutput("Case #" & $(caseIndex + 1) & ":\n")
  appendOutput("Total Amount Include GST: ")
  appendMoney(totalWithGst)
  outputBuffer.add '\n'
  appendOutput("Total Amount GST Paid: ")
  appendMoney(totalGst)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

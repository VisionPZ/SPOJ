const flushBlockBytes = 1 shl 17
const minimumBase = 2

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. caseCount:
  let message = nextToken(inputData, scanPos)
  var symbolSeen = newSeq[bool](256)
  var symbolDigit = newSeq[int](256)
  for symbolCode in 0 .. 255:
    symbolDigit[symbolCode] = -1
  var distinctCount = 0
  for messageIndex in 0 .. message.len - 1:
    let symbolCode = int(message[messageIndex])
    if not symbolSeen[symbolCode]:
      symbolSeen[symbolCode] = true
      distinctCount += 1
  var numberBase = distinctCount
  if numberBase < minimumBase:
    numberBase = minimumBase
  for symbolCode in 0 .. 255:
    symbolSeen[symbolCode] = false
  var usedDigits = newSeq[bool](numberBase)
  var firstSymbol = true
  for messageIndex in 0 .. message.len - 1:
    let symbolCode = int(message[messageIndex])
    if not symbolSeen[symbolCode]:
      symbolSeen[symbolCode] = true
      var chosenDigit = 0
      if firstSymbol:
        chosenDigit = 1
      else:
        while usedDigits[chosenDigit]:
          chosenDigit += 1
      symbolDigit[symbolCode] = chosenDigit
      usedDigits[chosenDigit] = true
      firstSymbol = false
  var smallestValue: int64 = 0
  for messageIndex in 0 .. message.len - 1:
    let digitValue = symbolDigit[int(message[messageIndex])]
    smallestValue = smallestValue * int64(numberBase) + int64(digitValue)
  appendOutput("Case #" & $caseNumber & ": " & $smallestValue & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0

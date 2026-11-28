const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

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

let firstToken = nextToken(inputData, scanPos)
let secondToken = nextToken(inputData, scanPos)
var longestLength = firstToken.len
if secondToken.len > longestLength:
  longestLength = secondToken.len

var sumDigits: seq[char] = @[]
sumDigits.setLen(longestLength + 1)
var firstPos = firstToken.len - 1
var secondPos = secondToken.len - 1
var storedCount = 0
var carry = 0
while firstPos >= 0 or secondPos >= 0 or carry > 0:
  var columnTotal = carry
  if firstPos >= 0:
    columnTotal += int(firstToken[firstPos]) - firstDigitValue
    firstPos -= 1
  if secondPos >= 0:
    columnTotal += int(secondToken[secondPos]) - firstDigitValue
    secondPos -= 1
  sumDigits[storedCount] = char(columnTotal mod 10 + firstDigitValue)
  storedCount += 1
  carry = columnTotal div 10

while storedCount > 1 and sumDigits[storedCount - 1] == char(firstDigitValue):
  storedCount -= 1
var sumText = ""
for index in countdown(storedCount - 1, 0):
  sumText.add sumDigits[index]
appendOutput(sumText)
appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0

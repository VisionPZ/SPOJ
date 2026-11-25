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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let startPos = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[startPos .. pos - 1]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let keyDigits = nextWord(inputData, scanPos)
  let encodedMessage = nextWord(inputData, scanPos)
  let keyLength = keyDigits.len
  let bounceLength = 2 * keyLength
  var decodedMessage = newString(encodedMessage.len)
  var bounceTick = 0
  for messageIndex in 0 .. encodedMessage.len - 1:
    var digitPosition = bounceTick mod bounceLength
    if digitPosition >= keyLength:
      digitPosition = bounceLength - 1 - digitPosition
    let shift = int(keyDigits[digitPosition]) - 48
    let originalCode = (int(encodedMessage[messageIndex]) - 97 - shift + 26) mod 26
    decodedMessage[messageIndex] = chr(originalCode + 97)
    bounceTick += 1
  appendOutput(decodedMessage)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

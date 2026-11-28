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

proc gcdPair(leftValue: int, rightValue: int): int =
  var largerValue = leftValue
  var smallerValue = rightValue
  while smallerValue != 0:
    let remainder = largerValue mod smallerValue
    largerValue = smallerValue
    smallerValue = remainder
  return largerValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let numberCount = nextInt(inputData, scanPos)
var runningGcd = 0
var readIndex = 0
while readIndex < numberCount and runningGcd != 1:
  runningGcd = gcdPair(runningGcd, nextInt(inputData, scanPos))
  readIndex += 1
appendOutput($runningGcd)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

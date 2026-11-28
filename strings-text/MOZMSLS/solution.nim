const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and data[position] <= ' ':
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value

proc nextToken(data: string, position: var int): string =
  while position < data.len and data[position] <= ' ':
    position += 1
  var token = ""
  while position < data.len and data[position] > ' ':
    token.add data[position]
    position += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let sourceText = nextToken(inputData, scanPos)
let textLength = sourceText.len
var prefixS: seq[int64]
prefixS.setLen(textLength + 1)
var prefixBefore: seq[int64]
prefixBefore.setLen(textLength + 1)
var prefixSquares: seq[int64]
prefixSquares.setLen(textLength + 1)
var prefixMiddles: seq[int64]
prefixMiddles.setLen(textLength + 1)
for index in 1..textLength:
  let character = sourceText[index - 1]
  prefixS[index] = prefixS[index - 1]
  prefixBefore[index] = prefixBefore[index - 1]
  prefixSquares[index] = prefixSquares[index - 1]
  prefixMiddles[index] = prefixMiddles[index - 1]
  if character == 's':
    prefixS[index] += 1
  elif character == 'm':
    let earlierS = prefixS[index - 1]
    prefixBefore[index] += earlierS
    prefixSquares[index] += earlierS * earlierS
    prefixMiddles[index] += 1

let queryCount = nextInt(inputData, scanPos)
for queryIndex in 0..<queryCount:
  let left = nextInt(inputData, scanPos)
  let right = nextInt(inputData, scanPos)
  let beforeWindow = prefixS[left - 1]
  let upToRight = prefixS[right]
  let middleTotal = prefixMiddles[right] - prefixMiddles[left - 1]
  let beforeSum = prefixBefore[right] - prefixBefore[left - 1]
  let squareSum = prefixSquares[right] - prefixSquares[left - 1]
  let answer = upToRight * beforeSum - squareSum - beforeWindow * upToRight * middleTotal + beforeWindow * beforeSum
  appendOutput($(answer) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0

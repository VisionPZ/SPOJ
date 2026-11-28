const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const alphabetSize = 26

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
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

let textLength = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
let sourceText = nextToken(inputData, scanPos)

var prefixCounts: seq[array[alphabetSize, int32]]
prefixCounts.setLen(textLength + 1)
for index in 0..<textLength:
  prefixCounts[index + 1] = prefixCounts[index]
  let letterIndex = ord(sourceText[index]) - ord('a')
  if letterIndex >= 0 and letterIndex < alphabetSize:
    prefixCounts[index + 1][letterIndex] += 1

for queryIndex in 0..<queryCount:
  let leftIndex = nextInt(inputData, scanPos) - 1
  let rightIndex = nextInt(inputData, scanPos)
  var bestLetter = 0
  var bestCount = int32(-1)
  for letterIndex in 0..<alphabetSize:
    let currentCount = prefixCounts[rightIndex][letterIndex] - prefixCounts[leftIndex][letterIndex]
    if currentCount > bestCount:
      bestCount = currentCount
      bestLetter = letterIndex
  appendOutput($(char(ord('a') + bestLetter)) & " " & $(int(bestCount)) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0

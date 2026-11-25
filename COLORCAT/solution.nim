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

proc skipSpace(data: string, pos: var int) =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let catCount = nextInt(inputData, scanPos)
let stepCount = nextInt(inputData, scanPos)
skipSpace(inputData, scanPos)
var colorValues = newSeq[uint8](catCount)
for catIndex in 0 .. catCount - 1:
  let symbol = inputData[scanPos]
  scanPos += 1
  if symbol == 'W':
    colorValues[catIndex] = 0'u8
  elif symbol == 'R':
    colorValues[catIndex] = 1'u8
  else:
    colorValues[catIndex] = 2'u8
var combineTable: array[9, uint8]
for leftColor in 0 .. 2:
  for rightColor in 0 .. 2:
    combineTable[leftColor * 3 + rightColor] = uint8((3 - ((leftColor + rightColor) mod 3)) mod 3)
for stepIndex in 0 .. stepCount - 1:
  var leftColor = colorValues[0]
  for pairIndex in 0 .. catCount - 2:
    let rightColor = colorValues[pairIndex + 1]
    let newColor = combineTable[int(leftColor) * 3 + int(rightColor)]
    colorValues[pairIndex] = newColor
    leftColor = newColor
  let finalColor = combineTable[int(leftColor) * 3 + int(colorValues[0])]
  colorValues[catCount - 1] = finalColor
  colorValues[0] = finalColor
const colorLetters = "WRG"
var resultText = newString(catCount)
for catIndex in 0 .. catCount - 1:
  resultText[catIndex] = colorLetters[int(colorValues[catIndex])]
appendOutput(resultText)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

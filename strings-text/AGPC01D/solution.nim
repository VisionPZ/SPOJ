const flushBlockBytes = 1 shl 17
const alphabetSize = 26
const lowercaseOrigin = 97

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
  var word = ""
  while pos < data.len and data[pos] > ' ':
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let sizeA = nextInt(inputData, scanPos)
  let sizeB = nextInt(inputData, scanPos)
  discard sizeA
  discard sizeB
  let sourceWord = nextWord(inputData, scanPos)
  let targetWord = nextWord(inputData, scanPos)
  var available: array[alphabetSize, int]
  var required: array[alphabetSize, int]
  for letterIndex in 0 .. sourceWord.len - 1:
    let slot = int(sourceWord[letterIndex]) - lowercaseOrigin
    if slot >= 0 and slot < alphabetSize:
      available[slot] += 1
  for letterIndex in 0 .. targetWord.len - 1:
    let slot = int(targetWord[letterIndex]) - lowercaseOrigin
    if slot >= 0 and slot < alphabetSize:
      required[slot] += 1
  var copyCount = -1
  for slot in 0 .. alphabetSize - 1:
    if required[slot] > 0:
      let possible = available[slot] div required[slot]
      if copyCount < 0 or possible < copyCount:
        copyCount = possible
  if copyCount < 0:
    copyCount = 0
  appendOutput($copyCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

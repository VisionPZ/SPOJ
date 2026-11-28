const firstLowerCode = 97
const alphabetSize = 26
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextLetter(data: string, position: var int): char =
  while position < data.len and (data[position] < 'a' or data[position] > 'z'):
    position += 1
  let foundLetter = data[position]
  position += 1
  return foundLetter

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let startLetter = nextLetter(inputData, scanPos)
let endLetter = nextLetter(inputData, scanPos)
let startCode = ord(startLetter) - firstLowerCode
let endCode = ord(endLetter) - firstLowerCode
let stepCount = (endCode - startCode + alphabetSize) mod alphabetSize
var answerText = ""
for step in 0..stepCount:
  if step > 0:
    answerText.add ' '
  answerText.add chr((startCode + step) mod alphabetSize + firstLowerCode)
answerText.add '\n'
appendOutput(answerText)

stdout.write outputBuffer
outputBuffer.setLen 0

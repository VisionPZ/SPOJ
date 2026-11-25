import algorithm

const flushBlockBytes = 1 shl 17
const firstUpperValue = 65
const firstLowerValue = 97
const alphabetSize = 26
const firstDigitValue = 48
const newlineCode = 10

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var headerEnd = 0
while headerEnd < inputData.len and inputData[headerEnd] != '\n':
  headerEnd += 1
var headerPos = 0
let lineCount = nextInt(inputData[0 .. headerEnd - 1], headerPos)

var letterCounts = newSeq[int](alphabetSize)
var linesConsumed = 0
var bytePos = headerEnd + 1
while bytePos < inputData.len and linesConsumed < lineCount:
  let byteCode = ord(inputData[bytePos])
  if byteCode == newlineCode:
    linesConsumed += 1
  elif byteCode >= firstUpperValue and byteCode <= firstUpperValue + alphabetSize - 1:
    letterCounts[byteCode - firstUpperValue] += 1
  elif byteCode >= firstLowerValue and byteCode <= firstLowerValue + alphabetSize - 1:
    letterCounts[byteCode - firstLowerValue] += 1
  bytePos += 1

var presentLetters: seq[int] = @[]
for letterIndex in 0 .. alphabetSize - 1:
  if letterCounts[letterIndex] > 0:
    presentLetters.add letterIndex

proc compareLetters(leftIndex: int, rightIndex: int): int =
  if letterCounts[leftIndex] > letterCounts[rightIndex]:
    return -1
  if letterCounts[leftIndex] < letterCounts[rightIndex]:
    return 1
  if leftIndex > rightIndex:
    return -1
  if leftIndex < rightIndex:
    return 1
  return 0

sort(presentLetters, compareLetters)

for letterIndex in presentLetters:
  appendOutput($chr(firstUpperValue + letterIndex))
  appendOutput(" ")
  appendOutput($letterCounts[letterIndex])
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0

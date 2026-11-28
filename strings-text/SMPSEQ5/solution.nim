const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let sourceCount = nextInt(inputData, scanPos)
var sourceValues = newSeq[int](sourceCount)
for index in 0 ..< sourceCount:
  sourceValues[index] = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
var queryValues = newSeq[int](queryCount)
for index in 0 ..< queryCount:
  queryValues[index] = nextInt(inputData, scanPos)
var sharedLimit = sourceCount
if queryCount < sharedLimit:
  sharedLimit = queryCount
var matchedIndexes = newSeq[int]()
for index in 0 ..< sharedLimit:
  if sourceValues[index] == queryValues[index]:
    matchedIndexes.add index + 1
for index in 0 ..< matchedIndexes.len:
  if index > 0:
    appendOutput(" ")
  appendOutput($(matchedIndexes[index]))
outputBuffer.add '\n'
stdout.write outputBuffer

const firstDigitValue = 48
const valueOffset = 100
const valueSpan = 201
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
var presentInQuery = newSeq[bool](valueSpan)
for index in 0 ..< queryCount:
  let queriedValue = nextInt(inputData, scanPos)
  presentInQuery[queriedValue + valueOffset] = true
var keptValues = newSeq[int]()
for index in 0 ..< sourceCount:
  let candidate = sourceValues[index]
  if presentInQuery[candidate + valueOffset]:
    keptValues.add candidate
for index in 0 ..< keptValues.len:
  appendOutput($(keptValues[index]))
  appendOutput(" ")
outputBuffer.add '\n'
stdout.write outputBuffer

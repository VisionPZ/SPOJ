const flushBlockBytes = 1 shl 17
const valueOffset = 20000
const tableSize = 40001

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
var presence = newSeq[bool](tableSize)
var caseIndex = 1
while caseIndex <= caseCount:
  let valueCount = nextInt(inputData, scanPos)
  for slot in 0 .. tableSize - 1:
    presence[slot] = false
  var values = newSeq[int](valueCount)
  for valueIndex in 0 .. valueCount - 1:
    values[valueIndex] = nextInt(inputData, scanPos)
    presence[values[valueIndex] + valueOffset] = true
  var doubleCount = 0
  for valueIndex in 0 .. valueCount - 1:
    let doubledValue = 2 * values[valueIndex]
    if presence[doubledValue + valueOffset]:
      doubleCount += 1
  appendOutput($doubleCount)
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0

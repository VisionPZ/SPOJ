import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt(data: string, position: var int): int64 =
  while position < data.len and data[position] != '-' and (data[position] < '0' or data[position] > '9'):
    position += 1
  var negative = false
  if position < data.len and data[position] == '-':
    negative = true
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc increasingOrder(left, right: int64): int =
  if left < right:
    return -1
  if left > right:
    return 1
  return 0

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = int(nextSignedInt(inputData, scanPos))
var values = newSeq[int64](0)
for caseIndex in 0..<caseCount:
  let elementCount = int(nextSignedInt(inputData, scanPos))
  values.setLen elementCount
  for i in 0..<elementCount:
    values[i] = nextSignedInt(inputData, scanPos)
  sort(values, increasingOrder)
  var closestGap = values[1] - values[0]
  for i in 1..<elementCount:
    let gap = values[i] - values[i - 1]
    if gap < closestGap:
      closestGap = gap
  appendOutput($closestGap & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0

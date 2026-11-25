const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

proc gcdValues(firstValue, secondValue: int64): int64 =
  var larger = firstValue
  var smaller = secondValue
  while smaller != 0:
    let remainder = larger mod smaller
    larger = smaller
    smaller = remainder
  return larger

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let moduloBase = nextInt(inputData, scanPos)
let visitStride = nextInt(inputData, scanPos)
let commonStep = gcdValues(moduloBase, visitStride)
var totalCost: int64 = 0
if commonStep == 1:
  totalCost = moduloBase * (moduloBase - 1) div 2
else:
  let distinctCount = moduloBase div commonStep
  totalCost = distinctCount + commonStep * distinctCount * (distinctCount - 1) div 2

appendOutput($totalCost)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

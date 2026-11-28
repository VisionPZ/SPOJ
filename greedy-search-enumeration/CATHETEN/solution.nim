const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const sieveLimit = 31623

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var composite = newSeq[bool](sieveLimit + 1)
var primeList: seq[int] = @[]
var sieveIndex = 2
while sieveIndex <= sieveLimit:
  if not composite[sieveIndex]:
    primeList.add sieveIndex
    var multipleIndex = sieveIndex * sieveIndex
    while multipleIndex <= sieveLimit:
      composite[multipleIndex] = true
      multipleIndex += sieveIndex
  sieveIndex += 1

let caseCount = nextInt(inputData, scanPos)
var caseIndex = 0
while caseIndex < caseCount:
  let legLength = nextInt(inputData, scanPos)
  var core = legLength
  if (core mod 2) == 0:
    core = core div 2
  var divisorCount: int64 = 1
  var remaining = core
  var primeIndex = 0
  while primeIndex < primeList.len:
    let primeValue = primeList[primeIndex]
    if primeValue * primeValue > remaining:
      break
    if (remaining mod primeValue) == 0:
      var exponent = 0
      while (remaining mod primeValue) == 0:
        exponent += 1
        remaining = remaining div primeValue
      divisorCount = divisorCount * int64(2 * exponent + 1)
    primeIndex += 1
  if remaining > 1:
    divisorCount = divisorCount * 3
  let triangleCount = (divisorCount - 1) div 2
  appendOutput($triangleCount)
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0

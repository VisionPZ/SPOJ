import math

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc gcdValues(first: int64, second: int64): int64 =
  var left = first
  var right = second
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  return left

let testCount = nextInt(inputData, scanPos)
var lowerBounds = newSeq[int](testCount)
var upperBounds = newSeq[int](testCount)
var maxUpper = 0
for queryIndex in 0 .. testCount - 1:
  lowerBounds[queryIndex] = nextInt(inputData, scanPos)
  upperBounds[queryIndex] = nextInt(inputData, scanPos)
  if upperBounds[queryIndex] > maxUpper:
    maxUpper = upperBounds[queryIndex]

var legOneList = newSeq[int64](0)
var legTwoList = newSeq[int64](0)
var hypotenuseList = newSeq[int64](0)
let rootLimit = int(sqrt(float(maxUpper))) + 1
for mValue in 2 .. rootLimit:
  for nValue in 1 .. mValue - 1:
    let hypotenuse = int64(mValue * mValue + nValue * nValue)
    if hypotenuse > int64(maxUpper):
      break
    if (mValue - nValue) mod 2 == 0:
      continue
    if gcdValues(int64(mValue), int64(nValue)) != 1:
      continue
    let legOne = int64(mValue * mValue - nValue * nValue)
    let legTwo = int64(2 * mValue * nValue)
    legOneList.add legOne
    legTwoList.add legTwo
    hypotenuseList.add hypotenuse

for queryIndex in 0 .. testCount - 1:
  let lowerBound = int64(lowerBounds[queryIndex])
  let upperBound = int64(upperBounds[queryIndex])
  var tripleCount: int64 = 0
  for tripleIndex in 0 .. hypotenuseList.len - 1:
    let hypotenuse = hypotenuseList[tripleIndex]
    if hypotenuse > upperBound:
      continue
    let smallLeg = min(legOneList[tripleIndex], legTwoList[tripleIndex])
    let firstMultiple = (lowerBound + smallLeg - 1) div smallLeg
    let lastMultiple = upperBound div hypotenuse
    if lastMultiple >= firstMultiple:
      tripleCount = tripleCount + lastMultiple - firstMultiple + 1
  appendOutput($tripleCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const letterCount = 26
const maxInputValue = 10000000
const rootLimit = 3163

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let initialText = nextToken(inputData, scanPos)
let stringLength = initialText.len
let queryCount = nextInt(inputData, scanPos)
let rowStride = stringLength + 1
var fenwick = newSeq[int]((letterCount + 1) * rowStride)
var cellLetter = newSeq[int](stringLength + 1)

proc fenwickAdd(position: int, letterIndex: int, deltaValue: int) =
  var treePosition = position
  while treePosition <= stringLength:
    fenwick[letterIndex * rowStride + treePosition] += deltaValue
    treePosition += treePosition and (-treePosition)

proc fenwickPrefix(position: int, letterIndex: int): int =
  result = 0
  var treePosition = position
  while treePosition > 0:
    result += fenwick[letterIndex * rowStride + treePosition]
    treePosition -= treePosition and (-treePosition)

var isPrime = newSeq[bool](rootLimit + 1)
for index in 0 .. rootLimit:
  isPrime[index] = true
isPrime[0] = false
isPrime[1] = false
var primeList: seq[int] = @[]
for candidate in 2 .. rootLimit:
  if isPrime[candidate]:
    primeList.add candidate
    if candidate * candidate <= rootLimit:
      var multiple = candidate * candidate
      while multiple <= rootLimit:
        isPrime[multiple] = false
        multiple += candidate

var divisorCache = newSeq[int32](maxInputValue + 1)

proc smallestDivisor(value: int): int =
  for primeValue in primeList:
    if primeValue * primeValue > value:
      return value
    if value mod primeValue == 0:
      return primeValue
  return value

for queryIndex in 0 .. queryCount - 1:
  let commandToken = nextToken(inputData, scanPos)
  if commandToken == "Update":
    let valueX = nextInt(inputData, scanPos)
    let letterToken = nextToken(inputData, scanPos)
    let letterIndex = int(letterToken[0]) - 96
    var baseDivisor = int(divisorCache[valueX])
    if baseDivisor == 0:
      baseDivisor = smallestDivisor(valueX)
      divisorCache[valueX] = int32(baseDivisor)
    var powerPosition = baseDivisor
    while powerPosition <= stringLength:
      let previousLetter = cellLetter[powerPosition]
      if previousLetter > 0:
        fenwickAdd(powerPosition, previousLetter, -1)
      cellLetter[powerPosition] = letterIndex
      fenwickAdd(powerPosition, letterIndex, 1)
      if baseDivisor > stringLength div powerPosition:
        break
      powerPosition = powerPosition * baseDivisor
  else:
    let leftBound = nextInt(inputData, scanPos)
    let rightBound = nextInt(inputData, scanPos)
    let letterToken = nextToken(inputData, scanPos)
    let letterIndex = int(letterToken[0]) - 96
    let answer = fenwickPrefix(rightBound, letterIndex) - fenwickPrefix(leftBound - 1, letterIndex)
    appendOutput($answer)
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

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

proc integerSquareRoot(value: int64): int64 =
  var guess = int64(sqrt(float(value)))
  while (guess + 1) * (guess + 1) <= value:
    guess += 1
  while guess * guess > value:
    guess -= 1
  return guess

proc integerCubeRoot(value: int64): int64 =
  var guess = int64(pow(float(value), 1.0 / 3.0))
  while (guess + 1) * (guess + 1) * (guess + 1) <= value:
    guess += 1
  while guess * guess * guess > value:
    guess -= 1
  return guess

proc pairCount(limitValue: int64): int64 =
  let rootValue = integerSquareRoot(limitValue)
  var totalPairs: int64 = 0
  var divisorValue: int64 = 1
  while divisorValue <= rootValue:
    totalPairs = totalPairs + limitValue div divisorValue
    divisorValue += 1
  return 2 * totalPairs - rootValue * rootValue

proc tripleCount(limitValue: int64): int64 =
  let splitIndex = integerCubeRoot(limitValue)
  var answer: int64 = 0
  var levelIndex: int64 = 1
  while levelIndex <= splitIndex:
    let remainingValue = limitValue div levelIndex
    let allPairs = pairCount(remainingValue)
    var prefixBefore: int64 = 0
    var prefixThrough: int64 = 0
    var divisorValue: int64 = 1
    while divisorValue <= levelIndex:
      prefixThrough = prefixThrough + remainingValue div divisorValue
      if divisorValue < levelIndex:
        prefixBefore = prefixThrough
      divisorValue += 1
    let beforeCount = allPairs - 2 * prefixBefore + (levelIndex - 1) * (levelIndex - 1)
    let middleCount = allPairs - prefixThrough - prefixBefore + levelIndex * (levelIndex - 1)
    let afterCount = allPairs - 2 * prefixThrough + levelIndex * levelIndex
    answer = answer + beforeCount + middleCount + afterCount
    levelIndex += 1
  return answer

var caseIndex = 0
while scanPos < inputData.len:
  let limitValue = nextInt(inputData, scanPos)
  if limitValue == 0 and scanPos >= inputData.len:
    break
  if limitValue < 1:
    continue
  caseIndex += 1
  appendOutput("Case " & $caseIndex & ": " & $tripleCount(int64(limitValue)))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

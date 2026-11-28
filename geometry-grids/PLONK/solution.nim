{.push checks: off.}

import algorithm

const
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18
  maxCoordValue = 100000

proc compareInts(left, right: int): int =
  if left < right:
    return -1
  if left > right:
    return 1
  return 0

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var costAtX: array[0..maxCoordValue, int64]
var costAtY: array[0..maxCoordValue, int64]

let caseCount = nextInt(inputData, scanPos)
for k in 0..<caseCount:
  let friendCount = nextInt(inputData, scanPos)
  var coordX: seq[int] = @[]
  var coordY: seq[int] = @[]
  coordX.setLen(friendCount)
  coordY.setLen(friendCount)
  var totalX = 0'i64
  var totalY = 0'i64
  for i in 0..<friendCount:
    let x = nextInt(inputData, scanPos)
    let y = nextInt(inputData, scanPos)
    coordX[i] = x
    coordY[i] = y
    totalX += x
    totalY += y

  var sortedX = coordX
  var sortedY = coordY
  sortedX.sort(compareInts)
  sortedY.sort(compareInts)

  var prefixX: seq[int64] = @[]
  var prefixY: seq[int64] = @[]
  prefixX.setLen(friendCount + 1)
  prefixY.setLen(friendCount + 1)
  for i in 0..<friendCount:
    prefixX[i + 1] = prefixX[i] + sortedX[i]
    prefixY[i + 1] = prefixY[i] + sortedY[i]

  var l = 0
  while l < friendCount:
    var j = l + 1
    while j < friendCount and sortedX[j] == sortedX[l]:
      j += 1
    let value = sortedX[l]
    costAtX[value] = int64(value) * l - prefixX[l] + (totalX - prefixX[j]) - int64(value) * (friendCount - j)
    l = j

  l = 0
  while l < friendCount:
    var j = l + 1
    while j < friendCount and sortedY[j] == sortedY[l]:
      j += 1
    let value = sortedY[l]
    costAtY[value] = int64(value) * l - prefixY[l] + (totalY - prefixY[j]) - int64(value) * (friendCount - j)
    l = j

  var minTotal = high(int64)
  for i in 0..<friendCount:
    let candidateTotal = costAtX[coordX[i]] + costAtY[coordY[i]]
    if candidateTotal < minTotal:
      minTotal = candidateTotal

  appendOutput($minTotal)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

const modulusValue = 1000000000
const flushBlockBytes = 1 shl 17
const maximumHeight = 40

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

proc hasNextInt(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc convolve(firstCounts: seq[int], secondCounts: seq[int], maxSize: int,
              firstMin: int, secondMin: int): seq[int] =
  var products = newSeq[int](maxSize + 1)
  var firstIndex = firstMin
  while firstIndex <= maxSize:
    if firstCounts[firstIndex] != 0:
      var secondIndex = secondMin
      while secondIndex + firstIndex <= maxSize:
        if secondCounts[secondIndex] != 0:
          var combined = int64(products[firstIndex + secondIndex])
          combined += int64(firstCounts[firstIndex]) * int64(secondCounts[secondIndex])
          products[firstIndex + secondIndex] = int(combined mod int64(modulusValue))
        secondIndex += 1
    firstIndex += 1
  return products

proc addShifted(target: var seq[int], source: seq[int]) =
  for sizeIndex in 0 .. target.len - 2:
    target[sizeIndex + 1] = (target[sizeIndex + 1] + source[sizeIndex]) mod modulusValue

var queryCounts = newSeq[int]()
while hasNextInt(inputData, scanPos):
  queryCounts.add nextInt(inputData, scanPos)

var largestQuery = 0
for requestedSize in queryCounts:
  if requestedSize > largestQuery:
    largestQuery = requestedSize

var minimumByHeight = newSeq[int](maximumHeight + 1)
minimumByHeight[0] = 1
minimumByHeight[1] = 2
var heightLimit = 1
while heightLimit + 1 <= maximumHeight and minimumByHeight[heightLimit] <= largestQuery:
  heightLimit += 1
  minimumByHeight[heightLimit] = 1 + minimumByHeight[heightLimit - 1] + minimumByHeight[heightLimit - 2]

var countsByHeight = newSeq[seq[int]](heightLimit + 1)
for level in 0 .. heightLimit:
  countsByHeight[level] = newSeq[int](largestQuery + 1)
countsByHeight[0][1] = 1

var emptyBase = newSeq[int](largestQuery + 1)
emptyBase[0] = 1
var firstLevel = newSeq[int](largestQuery + 1)
var leftRight = convolve(countsByHeight[0], emptyBase, largestQuery, 1, 0)
addShifted(firstLevel, leftRight)
var rightLeft = convolve(emptyBase, countsByHeight[0], largestQuery, 0, 1)
addShifted(firstLevel, rightLeft)
var bothSingle = convolve(countsByHeight[0], countsByHeight[0], largestQuery, 1, 1)
addShifted(firstLevel, bothSingle)
countsByHeight[1] = firstLevel

var level = 2
while level <= heightLimit:
  var equalPair = convolve(countsByHeight[level - 1], countsByHeight[level - 1],
                           largestQuery, minimumByHeight[level - 1], minimumByHeight[level - 1])
  var unevenPair = convolve(countsByHeight[level - 1], countsByHeight[level - 2],
                            largestQuery, minimumByHeight[level - 1], minimumByHeight[level - 2])
  var levelCounts = newSeq[int](largestQuery + 1)
  for sizeIndex in 0 .. largestQuery - 1:
    levelCounts[sizeIndex + 1] = (equalPair[sizeIndex] + 2 * unevenPair[sizeIndex]) mod modulusValue
  countsByHeight[level] = levelCounts
  level += 1

var totals = newSeq[int](largestQuery + 1)
for levelCounts in countsByHeight:
  for sizeIndex in 1 .. largestQuery:
    totals[sizeIndex] = (totals[sizeIndex] + levelCounts[sizeIndex]) mod modulusValue

for requestedSize in queryCounts:
  var digits = $totals[requestedSize]
  while digits.len < 9:
    digits = "0" & digits
  appendOutput(digits)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

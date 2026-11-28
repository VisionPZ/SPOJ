import std/algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc compareInts(first, second: int): int =
  return system.cmp(first, second)

var compressedValues: seq[int]
var nextFree: seq[int]

proc findNext(i: int): int =
  var root = i
  while nextFree[root] != root:
    root = nextFree[root]
  var j = i
  while nextFree[j] != j:
    var parent = nextFree[j]
    nextFree[j] = root
    j = parent
  return root

proc lowerBound(value: int): int =
  var i = 0
  var j = compressedValues.len
  while i < j:
    var k = (i + j) div 2
    if compressedValues[k] < value:
      i = k + 1
    else:
      j = k
  return i

let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  let posterCount = nextInt(inputData, i)
  var leftBounds = newSeq[int](posterCount)
  var rightBounds = newSeq[int](posterCount)
  compressedValues = newSeq[int](posterCount * 6)
  var l = 0
  for k in 0..<posterCount:
    let leftBound = nextInt(inputData, i)
    let rightBound = nextInt(inputData, i)
    leftBounds[k] = leftBound
    rightBounds[k] = rightBound
    compressedValues[l] = leftBound - 1
    l += 1
    compressedValues[l] = leftBound
    l += 1
    compressedValues[l] = leftBound + 1
    l += 1
    compressedValues[l] = rightBound - 1
    l += 1
    compressedValues[l] = rightBound
    l += 1
    compressedValues[l] = rightBound + 1
    l += 1
  sort(compressedValues, compareInts)
  var uniqueCount = 0
  for k in 0..<compressedValues.len:
    if k == 0 or compressedValues[k] != compressedValues[uniqueCount - 1]:
      compressedValues[uniqueCount] = compressedValues[k]
      uniqueCount += 1
  compressedValues.setLen(uniqueCount)
  nextFree = newSeq[int](uniqueCount + 1)
  for k in 0..uniqueCount:
    nextFree[k] = k
  var visibleCount = 0
  for k in countdown(posterCount - 1, 0):
    let i = lowerBound(leftBounds[k])
    let j = lowerBound(rightBounds[k])
    var l = findNext(i)
    if l <= j:
      visibleCount += 1
      while l <= j:
        nextFree[l] = findNext(l + 1)
        l = findNext(l)
  appendOutput($(visibleCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

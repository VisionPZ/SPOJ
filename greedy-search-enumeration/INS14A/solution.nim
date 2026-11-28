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

proc nextBinary(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '1'):
    pos += 1
  var collected = ""
  while pos < data.len and (data[pos] == '0' or data[pos] == '1'):
    collected.add data[pos]
    pos += 1
  return collected

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCaseCount = nextInt(inputData, scanPos)
for testCase in 0 .. testCaseCount - 1:
  let onesNeeded = nextInt(inputData, scanPos)
  let binaryString = nextBinary(inputData, scanPos)
  var onesPositions = newSeq[int]()
  for charIndex in 0 .. binaryString.len - 1:
    if binaryString[charIndex] == '1':
      onesPositions.add charIndex
  var adjustedPrefix = newSeq[int64](onesPositions.len + 1)
  for positionIndex in 0 .. onesPositions.len - 1:
    adjustedPrefix[positionIndex + 1] = adjustedPrefix[positionIndex] + int64(onesPositions[positionIndex] - positionIndex)
  let windowCount = onesPositions.len - onesNeeded + 1
  var minimumSwaps: int64 = int64(binaryString.len) * int64(binaryString.len)
  for windowStart in 0 .. windowCount - 1:
    let medianIndex = windowStart + onesNeeded div 2
    let medianValue = int64(onesPositions[medianIndex] - medianIndex)
    let leftCount = onesNeeded div 2
    let rightCount = onesNeeded - leftCount - 1
    let leftCost = medianValue * int64(leftCount) - (adjustedPrefix[medianIndex] - adjustedPrefix[windowStart])
    let windowEnd = windowStart + onesNeeded
    let rightCost = (adjustedPrefix[windowEnd] - adjustedPrefix[medianIndex + 1]) - medianValue * int64(rightCount)
    let windowCost = leftCost + rightCost
    if windowCost < minimumSwaps:
      minimumSwaps = windowCost
  appendOutput($minimumSwaps)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

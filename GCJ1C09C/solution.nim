const flushBlockBytes = 1 shl 17
const maxReleaseCount = 100
const dpStride = maxReleaseCount + 2
const impossibleCost = 1000000000000

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

let caseCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. caseCount:
  let cellCount = nextInt(inputData, scanPos)
  let releaseCount = nextInt(inputData, scanPos)
  var boundaries = newSeq[int](releaseCount + 2)
  boundaries[0] = 0
  for releaseIndex in 1 .. releaseCount:
    boundaries[releaseIndex] = nextInt(inputData, scanPos)
  boundaries[releaseCount + 1] = cellCount + 1
  var bestCosts = newSeq[int64](dpStride * dpStride)
  for spanLength in 1 .. releaseCount:
    for leftRelease in 1 .. releaseCount - spanLength + 1:
      let rightRelease = leftRelease + spanLength - 1
      let leftEdge = boundaries[leftRelease - 1]
      let rightEdge = boundaries[rightRelease + 1]
      var bestCost: int64 = impossibleCost
      for midRelease in leftRelease .. rightRelease:
        let leftCost = bestCosts[leftRelease * dpStride + midRelease - 1]
        let rightCost = bestCosts[(midRelease + 1) * dpStride + rightRelease]
        let bribeCost = int64(rightEdge - leftEdge - 2)
        let totalCost = leftCost + rightCost + bribeCost
        if totalCost < bestCost:
          bestCost = totalCost
      bestCosts[leftRelease * dpStride + rightRelease] = bestCost
  var answer: int64 = 0
  if releaseCount >= 1:
    answer = bestCosts[dpStride + releaseCount]
  appendOutput("Case #" & $caseNumber & ": " & $answer & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0

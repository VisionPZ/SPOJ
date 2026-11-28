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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let eggCount = nextInt(inputData, scanPos)
  let targetBroken = nextInt(inputData, scanPos)
  var breakCounts = newSeq[int64](eggCount)
  for eggIndex in 0 .. eggCount - 1:
    breakCounts[eggIndex] = int64(nextInt(inputData, scanPos))
  for sortIndex in 1 .. eggCount - 1:
    let keyCount = breakCounts[sortIndex]
    var holeIndex = sortIndex
    while holeIndex > 0 and breakCounts[holeIndex - 1] > keyCount:
      breakCounts[holeIndex] = breakCounts[holeIndex - 1]
      holeIndex -= 1
    breakCounts[holeIndex] = keyCount
  var previousRow = newSeq[int64](eggCount + 1)
  var currentRow = newSeq[int64](eggCount + 1)
  var hullSlope = newSeq[int64](eggCount + 2)
  var hullIntercept = newSeq[int64](eggCount + 2)
  for brokenTarget in 1 .. targetBroken:
    var hullCount = 0
    currentRow[0] = 0
    for availableEggs in brokenTarget .. eggCount:
      let lineSlope = breakCounts[availableEggs - 1]
      let lineIntercept = previousRow[availableEggs - 1] -
                          int64(availableEggs) * lineSlope
      while hullCount >= 2:
        let lowerSlope = hullSlope[hullCount - 2]
        let lowerIntercept = hullIntercept[hullCount - 2]
        let middleSlope = hullSlope[hullCount - 1]
        let middleIntercept = hullIntercept[hullCount - 1]
        if middleSlope == lowerSlope:
          if middleIntercept >= lowerIntercept:
            hullCount -= 1
            continue
          break
        if lineSlope == middleSlope:
          if lineIntercept <= middleIntercept:
            hullCount -= 1
            continue
          break
        let turnOld = (middleIntercept - lineIntercept) * (middleSlope - lowerSlope)
        let turnNew = (lowerIntercept - middleIntercept) * (lineSlope - middleSlope)
        if turnOld >= turnNew:
          hullCount -= 1
        else:
          break
      if hullCount > 0:
        let queryPoint = int64(availableEggs + 1)
        let topValue = hullIntercept[hullCount - 1] +
                       hullSlope[hullCount - 1] * queryPoint
        let newValue = lineIntercept + lineSlope * queryPoint
        if topValue > newValue:
          hullSlope[hullCount] = lineSlope
          hullIntercept[hullCount] = lineIntercept
          hullCount += 1
      else:
        hullSlope[hullCount] = lineSlope
        hullIntercept[hullCount] = lineIntercept
        hullCount += 1
      let queryPoint = int64(availableEggs + 1)
      while hullCount >= 2:
        let topValue = hullIntercept[hullCount - 1] +
                       hullSlope[hullCount - 1] * queryPoint
        let belowValue = hullIntercept[hullCount - 2] +
                         hullSlope[hullCount - 2] * queryPoint
        if topValue >= belowValue:
          hullCount -= 1
        else:
          break
      currentRow[availableEggs] = hullIntercept[hullCount - 1] +
                                  hullSlope[hullCount - 1] * queryPoint
    swap previousRow, currentRow
  appendOutput($previousRow[eggCount])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

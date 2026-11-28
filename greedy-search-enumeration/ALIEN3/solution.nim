const flushBlockBytes = 1 shl 17
const unreachableCost = 1000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseTotal = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseTotal - 1:
  let stationCount = nextInt(inputData, scanPos)
  let teleporterCount = nextInt(inputData, scanPos)
  var teleporterValues = newSeq[int](teleporterCount)
  var teleporterIndex = 0
  while teleporterIndex < teleporterCount:
    teleporterValues[teleporterIndex] = nextInt(inputData, scanPos)
    teleporterIndex += 1
  let destination = nextInt(inputData, scanPos)
  let visitLimit = nextInt(inputData, scanPos)
  let maskCount = 1 shl teleporterCount
  let stationTotal = stationCount + 1
  var visitCosts = newSeq[int16](maskCount * stationTotal)
  var cellIndex = 0
  while cellIndex < visitCosts.len:
    visitCosts[cellIndex] = int16(unreachableCost)
    cellIndex += 1
  visitCosts[0] = 0
  var adjustedCosts = newSeq[int](stationTotal)
  var bestAnswer = unreachableCost
  var usedMask = 0
  while usedMask < maskCount:
    var bestAdjusted = unreachableCost
    var stationIndex = 0
    while stationIndex < stationTotal:
      let storedCost = int(visitCosts[usedMask * stationTotal + stationIndex])
      if storedCost < unreachableCost:
        let adjustedCost = storedCost - stationIndex
        if adjustedCost < bestAdjusted:
          bestAdjusted = adjustedCost
      adjustedCosts[stationIndex] = bestAdjusted
      stationIndex += 1
    if bestAdjusted < unreachableCost div 2:
      let walkingAnswer = destination + adjustedCosts[destination]
      if walkingAnswer <= visitLimit and walkingAnswer < bestAnswer:
        bestAnswer = walkingAnswer
      teleporterIndex = 0
      while teleporterIndex < teleporterCount:
        if (usedMask and (1 shl teleporterIndex)) == 0:
          let nextMask = usedMask or (1 shl teleporterIndex)
          let teleporterShift = teleporterValues[teleporterIndex]
          stationIndex = 0
          while stationIndex < stationTotal:
            let adjustedCost = adjustedCosts[stationIndex]
            if adjustedCost < unreachableCost div 2:
              let arrivalCost = stationIndex + adjustedCost + 1
              if arrivalCost <= visitLimit:
                let landingStation = stationIndex + teleporterShift
                if landingStation >= 0 and landingStation <= stationCount:
                  let targetCell = nextMask * stationTotal + landingStation
                  if arrivalCost < int(visitCosts[targetCell]):
                    visitCosts[targetCell] = int16(arrivalCost)
            stationIndex += 1
        teleporterIndex += 1
    usedMask += 1
  var answer = -1
  if bestAnswer <= visitLimit:
    answer = bestAnswer
  appendOutput("Scenario #" & $(caseIndex + 1) & ": " & $answer & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0

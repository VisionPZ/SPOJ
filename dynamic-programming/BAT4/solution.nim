const flushBlockBytes = 1 shl 17
const unreachableCost = 1000000000

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
  let gridSize = nextInt(inputData, scanPos)
  let timeBudget = nextInt(inputData, scanPos)
  var buildingHeights = newSeq[seq[int]](gridSize)
  for rowIndex in 0 .. gridSize - 1:
    buildingHeights[rowIndex] = newSeq[int](gridSize)
    for colIndex in 0 .. gridSize - 1:
      buildingHeights[rowIndex][colIndex] = nextInt(inputData, scanPos)
  var minimumClimbs = newSeq[seq[int]](gridSize)
  for rowIndex in 0 .. gridSize - 1:
    minimumClimbs[rowIndex] = newSeq[int](gridSize)
  for rowIndex in 0 .. gridSize - 1:
    for colIndex in 0 .. gridSize - 1:
      if rowIndex == 0 and colIndex == 0:
        minimumClimbs[rowIndex][colIndex] = 0
      else:
        var bestClimb = unreachableCost
        if rowIndex > 0:
          let heightRise = buildingHeights[rowIndex][colIndex] - buildingHeights[rowIndex - 1][colIndex]
          var climbHere = minimumClimbs[rowIndex - 1][colIndex]
          if heightRise > climbHere:
            climbHere = heightRise
          if climbHere < bestClimb:
            bestClimb = climbHere
        if colIndex > 0:
          let heightRise = buildingHeights[rowIndex][colIndex] - buildingHeights[rowIndex][colIndex - 1]
          var climbHere = minimumClimbs[rowIndex][colIndex - 1]
          if heightRise > climbHere:
            climbHere = heightRise
          if climbHere < bestClimb:
            bestClimb = climbHere
        minimumClimbs[rowIndex][colIndex] = bestClimb
  let targetClimb = minimumClimbs[gridSize - 1][gridSize - 1]
  let slotStride = timeBudget
  var reachableTimes = newSeq[bool](gridSize * gridSize * timeBudget)
  for slotIndex in 0 .. reachableTimes.len - 1:
    reachableTimes[slotIndex] = false
  reachableTimes[0] = true
  for rowIndex in 0 .. gridSize - 1:
    for colIndex in 0 .. gridSize - 1:
      for spentTime in 0 .. timeBudget - 1:
        let sourceSlot = (rowIndex * gridSize + colIndex) * slotStride + spentTime
        if not reachableTimes[sourceSlot]:
          continue
        for successor in 0 .. 1:
          var nextRow = rowIndex
          var nextCol = colIndex
          if successor == 0:
            nextRow += 1
          else:
            nextCol += 1
          if nextRow >= gridSize or nextCol >= gridSize:
            continue
          let heightStep = buildingHeights[nextRow][nextCol] - buildingHeights[rowIndex][colIndex]
          if heightStep > targetClimb:
            continue
          var travelCost = heightStep
          if travelCost < 0:
            travelCost = -travelCost
          let nextTime = spentTime + travelCost
          if nextTime < timeBudget:
            let targetSlot = (nextRow * gridSize + nextCol) * slotStride + nextTime
            reachableTimes[targetSlot] = true
  var latestArrival = -1
  for spentTime in 0 .. timeBudget - 1:
    let targetSlot = ((gridSize - 1) * gridSize + gridSize - 1) * slotStride + spentTime
    if reachableTimes[targetSlot]:
      latestArrival = spentTime
  if latestArrival < 0:
    appendOutput("NO")
  else:
    appendOutput("YES : " & $targetClimb & " " & $(timeBudget - latestArrival))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

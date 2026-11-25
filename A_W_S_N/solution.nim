const flushBlockBytes = 1 shl 17
const unreachableCost = 1 shl 28

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

proc nextGridCell(data: string, pos: var int): char =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  let cellChar = data[pos]
  pos += 1
  return cellChar

proc bfsDistances(grid: seq[char], rowCount, columnCount, startIndex: int): seq[int] =
  result = newSeq[int](rowCount * columnCount)
  for cellIndex in 0 .. rowCount * columnCount - 1:
    result[cellIndex] = -1
  var queue = newSeq[int](rowCount * columnCount)
  var headIndex = 0
  var tailIndex = 0
  result[startIndex] = 0
  queue[tailIndex] = startIndex
  tailIndex += 1
  while headIndex < tailIndex:
    let currentIndex = queue[headIndex]
    headIndex += 1
    let currentRow = currentIndex div columnCount
    let currentColumn = currentIndex mod columnCount
    for deltaRow in -1 .. 1:
      for deltaColumn in -1 .. 1:
        if (deltaRow == 0 and deltaColumn == 0) or (deltaRow != 0 and deltaColumn != 0):
          continue
        let neighborRow = currentRow + deltaRow
        let neighborColumn = currentColumn + deltaColumn
        if neighborRow >= 0 and neighborRow < rowCount and neighborColumn >= 0 and neighborColumn < columnCount:
          let neighborIndex = neighborRow * columnCount + neighborColumn
          if grid[neighborIndex] != '#' and result[neighborIndex] == -1:
            result[neighborIndex] = result[currentIndex] + 1
            queue[tailIndex] = neighborIndex
            tailIndex += 1
  return result

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  var grid = newSeq[char](rowCount * columnCount)
  var startIndex = -1
  var destinationIndex = -1
  var chocolateIndices = newSeq[int]()
  for cellIndex in 0 .. rowCount * columnCount - 1:
    let cellChar = nextGridCell(inputData, scanPos)
    grid[cellIndex] = cellChar
    if cellChar == 'T':
      startIndex = cellIndex
    elif cellChar == 'W':
      destinationIndex = cellIndex
    elif cellChar == 'C':
      chocolateIndices.add cellIndex
  var importantIndices = newSeq[int]()
  importantIndices.add startIndex
  for chocolateIndex in chocolateIndices:
    importantIndices.add chocolateIndex
  importantIndices.add destinationIndex
  let importantCount = importantIndices.len
  var distanceTable = newSeq[seq[int]]()
  for pointIndex in 0 .. importantCount - 1:
    distanceTable.add bfsDistances(grid, rowCount, columnCount, importantIndices[pointIndex])
  let chocolateCount = chocolateIndices.len
  var answer = 0
  var possible = true
  if chocolateCount == 0:
    answer = distanceTable[0][destinationIndex]
    if answer < 0:
      possible = false
  else:
    let maskLimit = 1 shl chocolateCount
    let fullMask = maskLimit - 1
    var bestCosts = newSeq[int](maskLimit * chocolateCount)
    for costIndex in 0 .. bestCosts.len - 1:
      bestCosts[costIndex] = unreachableCost
    for chocolateSlot in 0 .. chocolateCount - 1:
      let chocolateIndex = chocolateIndices[chocolateSlot]
      let directDistance = distanceTable[0][chocolateIndex]
      if directDistance >= 0:
        bestCosts[(1 shl chocolateSlot) * chocolateCount + chocolateSlot] = directDistance
    for mask in 0 .. fullMask:
      for fromSlot in 0 .. chocolateCount - 1:
        let currentCost = bestCosts[mask * chocolateCount + fromSlot]
        if currentCost >= unreachableCost:
          continue
        if (mask and (1 shl fromSlot)) == 0:
          continue
        for toSlot in 0 .. chocolateCount - 1:
          if (mask and (1 shl toSlot)) != 0:
            continue
          let toChocolate = chocolateIndices[toSlot]
          let stepDistance = distanceTable[fromSlot + 1][toChocolate]
          if stepDistance < 0:
            continue
          let nextMask = mask or (1 shl toSlot)
          let candidateCost = currentCost + stepDistance
          let nextIndex = nextMask * chocolateCount + toSlot
          if candidateCost < bestCosts[nextIndex]:
            bestCosts[nextIndex] = candidateCost
    var bestTotal = unreachableCost
    for lastSlot in 0 .. chocolateCount - 1:
      let finalCost = bestCosts[fullMask * chocolateCount + lastSlot]
      if finalCost >= unreachableCost:
        continue
      let toDestination = distanceTable[lastSlot + 1][destinationIndex]
      if toDestination < 0:
        continue
      let totalCost = finalCost + toDestination
      if totalCost < bestTotal:
        bestTotal = totalCost
    if bestTotal >= unreachableCost:
      possible = false
    else:
      answer = bestTotal
  if possible:
    appendOutput($answer)
  else:
    appendOutput("Mission Failed!")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

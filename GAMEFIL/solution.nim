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

var caseNumber = 0
while true:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  if rowCount == 0 and columnCount == 0:
    break
  caseNumber += 1
  let cellCount = rowCount * columnCount
  let liveCellCount = nextInt(inputData, scanPos)
  var targetMask = 0
  for liveIndex in 0 .. liveCellCount - 1:
    let liveRow = nextInt(inputData, scanPos)
    let liveColumn = nextInt(inputData, scanPos)
    targetMask = targetMask or (1 shl (liveRow * columnCount + liveColumn))
  var neighborTable = newSeq[seq[int]](cellCount)
  for cellRow in 0 .. rowCount - 1:
    for cellColumn in 0 .. columnCount - 1:
      var neighborList = newSeq[int](8)
      var offsetIndex = 0
      for offsetRow in -1 .. 1:
        for offsetColumn in -1 .. 1:
          if offsetRow == 0 and offsetColumn == 0:
            continue
          let wrapRow = (cellRow + offsetRow + rowCount) mod rowCount
          let wrapColumn = (cellColumn + offsetColumn + columnCount) mod columnCount
          neighborList[offsetIndex] = wrapRow * columnCount + wrapColumn
          offsetIndex += 1
      neighborTable[cellRow * columnCount + cellColumn] = neighborList
  var neighborCounts = newSeq[int](cellCount)
  var ancestorCount = 0
  for parentMask in 0 .. (1 shl cellCount) - 1:
    for cellIndex in 0 .. cellCount - 1:
      neighborCounts[cellIndex] = 0
    for cellIndex in 0 .. cellCount - 1:
      if (parentMask and (1 shl cellIndex)) != 0:
        for offsetIndex in 0 .. 7:
          neighborCounts[neighborTable[cellIndex][offsetIndex]] += 1
    var nextMask = 0
    for cellIndex in 0 .. cellCount - 1:
      let occupied = (parentMask and (1 shl cellIndex)) != 0
      let neighborTotal = neighborCounts[cellIndex]
      let survives = occupied and (neighborTotal == 2 or neighborTotal == 3)
      let born = (not occupied) and neighborTotal == 3
      if survives or born:
        nextMask = nextMask or (1 shl cellIndex)
    if nextMask == targetMask:
      ancestorCount += 1
  appendOutput("Case " & $caseNumber & ": ")
  if ancestorCount == 0:
    appendOutput("Garden of Eden.\n")
  else:
    appendOutput($ancestorCount & " possible ancestors.\n")
stdout.write outputBuffer
outputBuffer.setLen 0

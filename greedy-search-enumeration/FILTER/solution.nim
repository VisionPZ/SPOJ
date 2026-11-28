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

proc nextImageRow(data: string, pos: var int, widthValue: int): int =
  while pos < data.len and (data[pos] == '\n' or data[pos] == '\r' or data[pos] == ' ' or data[pos] == '\t'):
    pos += 1
  var rowMask = 0
  for columnIndex in 0 .. widthValue - 1:
    if pos < data.len and data[pos] == '#':
      rowMask = rowMask or (1 shl columnIndex)
    pos += 1
  return rowMask

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var popcountValues = newSeq[int](256)
for valueIndex in 0 .. 255:
  var remaining = valueIndex
  var countBits = 0
  while remaining > 0:
    countBits += remaining and 1
    remaining = remaining div 2
  popcountValues[valueIndex] = countBits

type TripleTable = object
  starts: seq[int]
  bases: seq[uint16]
  followers: seq[uint8]
  columnCounts: seq[seq[int]]

var tableCache = newSeq[TripleTable](9)

proc buildTable(widthValue: int): TripleTable =
  let rowValues = 1 shl widthValue
  var counts = newSeq[int](rowValues)
  var columnCounts = newSeq[seq[int]](rowValues)
  for rowValue in 0 .. rowValues - 1:
    columnCounts[rowValue] = newSeq[int](widthValue)
    for columnIndex in 0 .. widthValue - 1:
      let leftColumn = if columnIndex > 0: columnIndex - 1 else: 0
      let rightColumn = if columnIndex + 1 < widthValue: columnIndex + 1 else: widthValue - 1
      columnCounts[rowValue][columnIndex] = ((rowValue shr leftColumn) and 1) + ((rowValue shr columnIndex) and 1) + ((rowValue shr rightColumn) and 1)
  for upperRow in 0 .. rowValues - 1:
    for middleRow in 0 .. rowValues - 1:
      for lowerRow in 0 .. rowValues - 1:
        var filteredRow = 0
        for columnIndex in 0 .. widthValue - 1:
          let totalCount = columnCounts[upperRow][columnIndex] + columnCounts[middleRow][columnIndex] + columnCounts[lowerRow][columnIndex]
          if totalCount >= 5:
            filteredRow = filteredRow or (1 shl columnIndex)
        counts[filteredRow] += 1
  var starts = newSeq[int](rowValues + 1)
  for valueIndex in 0 .. rowValues - 1:
    starts[valueIndex + 1] = starts[valueIndex] + counts[valueIndex]
  var cursors = newSeq[int](rowValues)
  for valueIndex in 0 .. rowValues - 1:
    cursors[valueIndex] = starts[valueIndex]
  var bases = newSeq[uint16](starts[rowValues])
  var followers = newSeq[uint8](starts[rowValues])
  for upperRow in 0 .. rowValues - 1:
    for middleRow in 0 .. rowValues - 1:
      let baseIndex = upperRow * rowValues + middleRow
      for lowerRow in 0 .. rowValues - 1:
        var filteredRow = 0
        for columnIndex in 0 .. widthValue - 1:
          let totalCount = columnCounts[upperRow][columnIndex] + columnCounts[middleRow][columnIndex] + columnCounts[lowerRow][columnIndex]
          if totalCount >= 5:
            filteredRow = filteredRow or (1 shl columnIndex)
        let writeAt = cursors[filteredRow]
        bases[writeAt] = uint16(baseIndex)
        followers[writeAt] = uint8(lowerRow)
        cursors[filteredRow] += 1
  return TripleTable(starts: starts, bases: bases, followers: followers, columnCounts: columnCounts)

proc solveImage(widthValue: int, heightValue: int, filteredRows: seq[int]): string =
  let rowValues = 1 shl widthValue
  if tableCache[widthValue].starts.len == 0:
    tableCache[widthValue] = buildTable(widthValue)
  let table = tableCache[widthValue]
  const unreachable = -1
  if heightValue == 1:
    var bestMin = 1 shl 29
    var bestMax = -1
    for entryIndex in table.starts[filteredRows[0]] .. table.starts[filteredRows[0] + 1] - 1:
      let baseIndex = int(table.bases[entryIndex])
      let lowerRow = int(table.followers[entryIndex])
      if baseIndex div rowValues != baseIndex mod rowValues or lowerRow != baseIndex mod rowValues:
        continue
      let blackCount = popcountValues[baseIndex mod rowValues]
      if blackCount < bestMin:
        bestMin = blackCount
      if blackCount > bestMax:
        bestMax = blackCount
    if bestMax < 0:
      return "Impossible"
    return $(bestMax - bestMin)
  var minimumCost = newSeq[int](rowValues * rowValues)
  var maximumCost = newSeq[int](rowValues * rowValues)
  for stateIndex in 0 .. rowValues * rowValues - 1:
    minimumCost[stateIndex] = unreachable
    maximumCost[stateIndex] = unreachable
  for entryIndex in table.starts[filteredRows[0]] .. table.starts[filteredRows[0] + 1] - 1:
    let baseIndex = int(table.bases[entryIndex])
    if baseIndex div rowValues != baseIndex mod rowValues:
      continue
    let lowerRow = int(table.followers[entryIndex])
    let blackCount = popcountValues[baseIndex div rowValues] + popcountValues[lowerRow]
    let stateIndex = baseIndex div rowValues * rowValues + lowerRow
    if blackCount < minimumCost[stateIndex] or minimumCost[stateIndex] == unreachable:
      minimumCost[stateIndex] = blackCount
    if blackCount > maximumCost[stateIndex]:
      maximumCost[stateIndex] = blackCount
  for rowIndex in 1 .. heightValue - 2:
    var nextMinimum = newSeq[int](rowValues * rowValues)
    var nextMaximum = newSeq[int](rowValues * rowValues)
    for stateIndex in 0 .. rowValues * rowValues - 1:
      nextMinimum[stateIndex] = unreachable
      nextMaximum[stateIndex] = unreachable
    for entryIndex in table.starts[filteredRows[rowIndex]] .. table.starts[filteredRows[rowIndex] + 1] - 1:
      let baseIndex = int(table.bases[entryIndex])
      if minimumCost[baseIndex] == unreachable:
        continue
      let lowerRow = int(table.followers[entryIndex])
      let stateIndex = (baseIndex mod rowValues) * rowValues + lowerRow
      let addedBlack = popcountValues[lowerRow]
      let candidateMin = minimumCost[baseIndex] + addedBlack
      let candidateMax = maximumCost[baseIndex] + addedBlack
      if candidateMin < nextMinimum[stateIndex] or nextMinimum[stateIndex] == unreachable:
        nextMinimum[stateIndex] = candidateMin
      if candidateMax > nextMaximum[stateIndex]:
        nextMaximum[stateIndex] = candidateMax
    minimumCost = nextMinimum
    maximumCost = nextMaximum
  var bestMin = 1 shl 29
  var bestMax = -1
  for entryIndex in table.starts[filteredRows[heightValue - 1]] .. table.starts[filteredRows[heightValue - 1] + 1] - 1:
    let baseIndex = int(table.bases[entryIndex])
    if minimumCost[baseIndex] == unreachable:
      continue
    let lowerRow = int(table.followers[entryIndex])
    if lowerRow != baseIndex mod rowValues:
      continue
    if minimumCost[baseIndex] < bestMin:
      bestMin = minimumCost[baseIndex]
    if maximumCost[baseIndex] > bestMax:
      bestMax = maximumCost[baseIndex]
  if bestMax < 0:
    return "Impossible"
  return $(bestMax - bestMin)

var caseNumber = 1
while true:
  let widthValue = nextInt(inputData, scanPos)
  let heightValue = nextInt(inputData, scanPos)
  if widthValue == 0 and heightValue == 0:
    break
  var filteredRows = newSeq[int](heightValue)
  for rowIndex in 0 .. heightValue - 1:
    filteredRows[rowIndex] = nextImageRow(inputData, scanPos, widthValue)
  appendOutput("Case " & $caseNumber & ": " & solveImage(widthValue, heightValue, filteredRows))
  outputBuffer.add '\n'
  caseNumber += 1

stdout.write outputBuffer
outputBuffer.setLen 0

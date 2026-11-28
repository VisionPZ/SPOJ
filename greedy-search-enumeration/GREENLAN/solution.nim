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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc lastPrefixIndex(prefix: seq[int], baseValue: int, lowIndex: int, highIndex: int): int =
  var lower = lowIndex
  var upper = highIndex
  while lower < upper:
    let middle = (lower + upper + 1) div 2
    if prefix[middle] <= baseValue:
      lower = middle
    else:
      upper = middle - 1
  return lower

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let landSize = nextInt(inputData, scanPos)
  var lakeFlags = newSeq[int](landSize * landSize)
  for rowIndex in 0 .. landSize - 1:
    let rowText = nextToken(inputData, scanPos)
    for colIndex in 0 .. landSize - 1:
      if rowText[colIndex] == 'X':
        lakeFlags[rowIndex * landSize + colIndex] = 1
  var columnPrefix = newSeq[int]((landSize + 1) * landSize)
  for colIndex in 0 .. landSize - 1:
    columnPrefix[colIndex] = 0
  for rowIndex in 0 .. landSize - 1:
    for colIndex in 0 .. landSize - 1:
      columnPrefix[(rowIndex + 1) * landSize + colIndex] =
        columnPrefix[rowIndex * landSize + colIndex] + lakeFlags[rowIndex * landSize + colIndex]
  var topBottomBad = newSeq[int](landSize)
  var outsideBad = newSeq[int](landSize)
  var anyColumn = newSeq[int](landSize)
  var innerColumn = newSeq[int](landSize)
  var badEnd = newSeq[int](landSize)
  var prefixTopBottom = newSeq[int](landSize + 3)
  var prefixOutside = newSeq[int](landSize + 3)
  var prefixEnd = newSeq[int](landSize + 1)
  var rectangleCount: int64 = 0
  for topRow in 0 .. landSize - 1:
    for bottomRow in topRow .. landSize - 1:
      for colIndex in 0 .. landSize - 1:
        topBottomBad[colIndex] = lakeFlags[topRow * landSize + colIndex] +
          lakeFlags[bottomRow * landSize + colIndex]
        var outsideTotal = 0
        if topRow > 0:
          outsideTotal += lakeFlags[(topRow - 1) * landSize + colIndex]
        if bottomRow + 1 < landSize:
          outsideTotal += lakeFlags[(bottomRow + 1) * landSize + colIndex]
        outsideBad[colIndex] = outsideTotal
        if columnPrefix[(bottomRow + 1) * landSize + colIndex] -
            columnPrefix[topRow * landSize + colIndex] > 0:
          anyColumn[colIndex] = 1
        else:
          anyColumn[colIndex] = 0
        if columnPrefix[bottomRow * landSize + colIndex] -
            columnPrefix[(topRow + 1) * landSize + colIndex] > 0:
          innerColumn[colIndex] = 1
        else:
          innerColumn[colIndex] = 0
      for colIndex in 0 .. landSize - 1:
        if anyColumn[colIndex] == 1 or
            (colIndex + 1 < landSize and innerColumn[colIndex + 1] == 1):
          badEnd[colIndex] = 1
        else:
          badEnd[colIndex] = 0
      prefixEnd[0] = 0
      for colIndex in 0 .. landSize - 1:
        prefixEnd[colIndex + 1] = prefixEnd[colIndex] + badEnd[colIndex]
      for fillIndex in 0 .. landSize + 2:
        prefixTopBottom[fillIndex] = 0
        prefixOutside[fillIndex] = 0
      for colIndex in 0 .. landSize + 1:
        if colIndex < landSize:
          prefixTopBottom[colIndex + 1] = prefixTopBottom[colIndex] + topBottomBad[colIndex]
          prefixOutside[colIndex + 1] = prefixOutside[colIndex] + outsideBad[colIndex]
        else:
          prefixTopBottom[colIndex + 1] = prefixTopBottom[colIndex]
          prefixOutside[colIndex + 1] = prefixOutside[colIndex]
      for leftCol in 0 .. landSize - 1:
        if anyColumn[leftCol] == 1 or
            (leftCol > 0 and innerColumn[leftCol - 1] == 1):
          continue
        let lowerCol = if leftCol > 0: leftCol - 1 else: 0
        let topBase = prefixTopBottom[lowerCol]
        let topLast = lastPrefixIndex(prefixTopBottom, topBase, lowerCol, landSize + 1)
        let topLimit = topLast - 2
        let outsideBase = prefixOutside[leftCol]
        let outsideLast = lastPrefixIndex(prefixOutside, outsideBase, leftCol, landSize + 1)
        let rightLimit = min(topLimit, outsideLast - 1)
        if rightLimit < leftCol:
          continue
        rectangleCount += int64(rightLimit - leftCol + 1) -
          int64(prefixEnd[rightLimit + 1] - prefixEnd[leftCol])
  appendOutput($rectangleCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

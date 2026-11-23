const flushBlockBytes = 1 shl 18

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos = scanPos + 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - 48
    scanPos = scanPos + 1
  return value

proc sortValues(values: var seq[int]) =
  if values.len < 2: return
  for i in 1 ..< values.len:
    var key = values[i]
    var j = i - 1
    while j >= 0 and values[j] > key:
      values[j + 1] = values[j]
      j = j - 1
    values[j + 1] = key

proc uniqueSorted(values: seq[int]): seq[int] =
  var deduped: seq[int]
  for value in values:
    if deduped.len == 0 or deduped[deduped.len - 1] != value:
      deduped.add value
  return deduped

proc findIndex(values: seq[int], target: int): int =
  var low = 0
  var high = values.len - 1
  while low <= high:
    var middle = (low + high) div 2
    if values[middle] == target: return middle
    if values[middle] < target: low = middle + 1
    else: high = middle - 1
  return low

proc largestWeightedRectangle(heights, prefixWidths: seq[int], columnCount: int, stack: var seq[int]): int =
  var bestArea = 0
  stack.setLen 0
  for columnIndex in 0 ..< columnCount:
    var currentHeight = heights[columnIndex]
    while stack.len > 0 and heights[stack[stack.len - 1]] >= currentHeight:
      var barIndex = stack[stack.len - 1]
      stack.setLen stack.len - 1
      var leftEdge = (if stack.len > 0: stack[stack.len - 1] + 1 else: 0)
      var spanWidth = prefixWidths[columnIndex] - prefixWidths[leftEdge]
      var area = heights[barIndex] * spanWidth
      if area > bestArea: bestArea = area
    stack.add columnIndex
  while stack.len > 0:
    var barIndex = stack[stack.len - 1]
    stack.setLen stack.len - 1
    var leftEdge = (if stack.len > 0: stack[stack.len - 1] + 1 else: 0)
    var spanWidth = prefixWidths[columnCount] - prefixWidths[leftEdge]
    var area = heights[barIndex] * spanWidth
    if area > bestArea: bestArea = area
  return bestArea

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var scanPos = 0
var caseCount = nextInt(inputData, scanPos)
var outputBuffer: string

for caseIndex in 1 .. caseCount:
  var squareSize = nextInt(inputData, scanPos)
  var rectangleCount = nextInt(inputData, scanPos)
  var cutLefts = newSeq[int](rectangleCount)
  var cutRights = newSeq[int](rectangleCount)
  var cutBottoms = newSeq[int](rectangleCount)
  var cutTops = newSeq[int](rectangleCount)
  var xCoords: seq[int] = @[0, squareSize]
  var yCoords: seq[int] = @[0, squareSize]
  for rectIndex in 0 ..< rectangleCount:
    var first = nextInt(inputData, scanPos)
    var second = nextInt(inputData, scanPos)
    var third = nextInt(inputData, scanPos)
    var fourth = nextInt(inputData, scanPos)
    cutLefts[rectIndex] = min(first, second)
    cutRights[rectIndex] = max(first, second)
    cutBottoms[rectIndex] = min(third, fourth)
    cutTops[rectIndex] = max(third, fourth)
    xCoords.add cutLefts[rectIndex]
    xCoords.add cutRights[rectIndex]
    yCoords.add cutBottoms[rectIndex]
    yCoords.add cutTops[rectIndex]

  sortValues xCoords
  sortValues yCoords
  xCoords = uniqueSorted(xCoords)
  yCoords = uniqueSorted(yCoords)
  var xCellCount = xCoords.len - 1
  var yCellCount = yCoords.len - 1
  var blocked = newSeq[bool](xCellCount * yCellCount)

  for rectIndex in 0 ..< rectangleCount:
    var leftIndex = findIndex(xCoords, cutLefts[rectIndex])
    var rightIndex = findIndex(xCoords, cutRights[rectIndex])
    var bottomIndex = findIndex(yCoords, cutBottoms[rectIndex])
    var topIndex = findIndex(yCoords, cutTops[rectIndex])
    for xi in leftIndex ..< rightIndex:
      var rowStart = xi * yCellCount
      for yi in bottomIndex ..< topIndex:
        blocked[rowStart + yi] = true

  var upHeights = newSeq[int](xCellCount)
  var prefixWidths = newSeq[int](xCellCount + 1)
  for xi in 0 ..< xCellCount:
    prefixWidths[xi + 1] = prefixWidths[xi] + (xCoords[xi + 1] - xCoords[xi])
  var histStack: seq[int]
  var bestArea = 0
  for yi in 0 ..< yCellCount:
    var cellHeight = yCoords[yi + 1] - yCoords[yi]
    for xi in 0 ..< xCellCount:
      if blocked[xi * yCellCount + yi]:
        upHeights[xi] = 0
      else:
        upHeights[xi] = upHeights[xi] + cellHeight
    var rowArea = largestWeightedRectangle(upHeights, prefixWidths, xCellCount, histStack)
    if rowArea > bestArea: bestArea = rowArea

  outputBuffer.add $bestArea
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer

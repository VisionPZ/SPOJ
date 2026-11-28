const flushBlockBytes = 1 shl 18

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ':
    i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
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
  for i in 0 ..< columnCount:
    var currentHeight = heights[i]
    while stack.len > 0 and heights[stack[stack.len - 1]] >= currentHeight:
      var j = stack[stack.len - 1]
      stack.setLen stack.len - 1
      var leftEdge = (if stack.len > 0: stack[stack.len - 1] + 1 else: 0)
      var spanWidth = prefixWidths[i] - prefixWidths[leftEdge]
      var area = heights[j] * spanWidth
      if area > bestArea: bestArea = area
    stack.add i
  while stack.len > 0:
    var j = stack[stack.len - 1]
    stack.setLen stack.len - 1
    var leftEdge = (if stack.len > 0: stack[stack.len - 1] + 1 else: 0)
    var spanWidth = prefixWidths[columnCount] - prefixWidths[leftEdge]
    var area = heights[j] * spanWidth
    if area > bestArea: bestArea = area
  return bestArea

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var i = 0
var caseCount = nextInt(inputData, i)
var outputBuffer: string

for l in 1 .. caseCount:
  var squareSize = nextInt(inputData, i)
  var rectangleCount = nextInt(inputData, i)
  var cutLefts = newSeq[int](rectangleCount)
  var cutRights = newSeq[int](rectangleCount)
  var cutBottoms = newSeq[int](rectangleCount)
  var cutTops = newSeq[int](rectangleCount)
  var xCoords: seq[int] = @[0, squareSize]
  var yCoords: seq[int] = @[0, squareSize]
  for k in 0 ..< rectangleCount:
    var first = nextInt(inputData, i)
    var second = nextInt(inputData, i)
    var third = nextInt(inputData, i)
    var fourth = nextInt(inputData, i)
    cutLefts[k] = min(first, second)
    cutRights[k] = max(first, second)
    cutBottoms[k] = min(third, fourth)
    cutTops[k] = max(third, fourth)
    xCoords.add cutLefts[k]
    xCoords.add cutRights[k]
    yCoords.add cutBottoms[k]
    yCoords.add cutTops[k]

  sortValues xCoords
  sortValues yCoords
  xCoords = uniqueSorted(xCoords)
  yCoords = uniqueSorted(yCoords)
  var xCellCount = xCoords.len - 1
  var yCellCount = yCoords.len - 1
  var blocked = newSeq[bool](xCellCount * yCellCount)

  for k in 0 ..< rectangleCount:
    var i = findIndex(xCoords, cutLefts[k])
    var j = findIndex(xCoords, cutRights[k])
    var bottomIndex = findIndex(yCoords, cutBottoms[k])
    var topIndex = findIndex(yCoords, cutTops[k])
    for xi in i ..< j:
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

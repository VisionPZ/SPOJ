{.passC: "-O2".}
{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxCellCount = 10000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var heights: array[0..maxCellCount, int]
var visited: array[0..maxCellCount, bool]
var heapLevel: array[0..maxCellCount, int]
var heapCell: array[0..maxCellCount, int]
var heapSize = 0
var poppedLevel = 0
var poppedCell = 0
var waterTotal: int64 = 0
var rowCount = 0
var colCount = 0

proc heapPush(level, cell: int) =
  var child = heapSize
  heapSize += 1
  while child > 0:
    let parent = (child - 1) div 2
    if heapLevel[parent] <= level: break
    heapLevel[child] = heapLevel[parent]
    heapCell[child] = heapCell[parent]
    child = parent
  heapLevel[child] = level
  heapCell[child] = cell

proc heapPop() =
  let topLevel = heapLevel[0]
  let topCell = heapCell[0]
  heapSize -= 1
  if heapSize > 0:
    let lastLevel = heapLevel[heapSize]
    let lastCell = heapCell[heapSize]
    var parent = 0
    while true:
      let leftChild = parent * 2 + 1
      if leftChild >= heapSize: break
      var smallerChild = leftChild
      let rightChild = leftChild + 1
      if rightChild < heapSize and heapLevel[rightChild] < heapLevel[leftChild]:
        smallerChild = rightChild
      if heapLevel[smallerChild] >= lastLevel: break
      heapLevel[parent] = heapLevel[smallerChild]
      heapCell[parent] = heapCell[smallerChild]
      parent = smallerChild
    heapLevel[parent] = lastLevel
    heapCell[parent] = lastCell
  poppedLevel = topLevel
  poppedCell = topCell

proc relaxNeighbor(neighbor: int, barrier: int) =
  if visited[neighbor]: return
  visited[neighbor] = true
  let neighborHeight = heights[neighbor]
  let waterLine = if barrier > neighborHeight: barrier else: neighborHeight
  if waterLine > neighborHeight:
    waterTotal += int64(waterLine - neighborHeight)
  heapPush(waterLine, neighbor)

let caseCount = nextInt(inputData, scanPos)
for i in 0..<caseCount:
  rowCount = nextInt(inputData, scanPos)
  colCount = nextInt(inputData, scanPos)
  let cellCount = rowCount * colCount
  for j in 0..<cellCount:
    heights[j] = nextInt(inputData, scanPos)
    visited[j] = false
  heapSize = 0
  waterTotal = 0
  for j in 0..<cellCount:
    let rowIndex = j div colCount
    let colIndex = j mod colCount
    if rowIndex == 0 or rowIndex == rowCount - 1 or colIndex == 0 or colIndex == colCount - 1:
      visited[j] = true
      heapPush(heights[j], j)
  while heapSize > 0:
    heapPop()
    let cell = poppedCell
    let barrier = poppedLevel
    let rowIndex = cell div colCount
    let colIndex = cell mod colCount
    if rowIndex > 0: relaxNeighbor(cell - colCount, barrier)
    if rowIndex + 1 < rowCount: relaxNeighbor(cell + colCount, barrier)
    if colIndex > 0: relaxNeighbor(cell - 1, barrier)
    if colIndex + 1 < colCount: relaxNeighbor(cell + 1, barrier)
  appendOutput($(waterTotal))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
{.pop.}

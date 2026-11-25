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

proc nextGridLine(data: string, pos: var int, width: int): string =
  while pos < data.len and (data[pos] == '\n' or data[pos] == '\r'):
    pos += 1
  result = ""
  while result.len < width and pos < data.len:
    let cellChar = data[pos]
    if cellChar != '\n' and cellChar != '\r' and cellChar != ' ':
      result.add cellChar
    pos += 1
  return result

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let mallCount = nextInt(inputData, scanPos)
for mallIndex in 0 .. mallCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  var grid = newSeq[string](rowCount)
  var carIndex = -1
  var storeIndices = newSeq[int](0)
  for rowIndex in 0 .. rowCount - 1:
    grid[rowIndex] = nextGridLine(inputData, scanPos, columnCount)
    for columnIndex in 0 .. columnCount - 1:
      let cellChar = grid[rowIndex][columnIndex]
      if cellChar == 'C':
        carIndex = rowIndex * columnCount + columnIndex
      elif cellChar == 'S':
        storeIndices.add(rowIndex * columnCount + columnIndex)
  let cellTotal = rowCount * columnCount
  var distances = newSeq[int](cellTotal)
  for cellIndex in 0 .. cellTotal - 1:
    distances[cellIndex] = -1
  var queue = newSeq[int](cellTotal)
  var headIndex = 0
  var tailIndex = 0
  distances[carIndex] = 0
  queue[tailIndex] = carIndex
  tailIndex += 1
  while headIndex < tailIndex:
    let currentIndex = queue[headIndex]
    headIndex += 1
    let currentRow = currentIndex div columnCount
    let currentColumn = currentIndex mod columnCount
    let currentDistance = distances[currentIndex]
    for direction in 0 .. 3:
      var nextRow = currentRow
      var nextColumn = currentColumn
      if direction == 0:
        nextRow -= 1
      elif direction == 1:
        nextRow += 1
      elif direction == 2:
        nextColumn -= 1
      else:
        nextColumn += 1
      if nextRow >= 0 and nextRow < rowCount and nextColumn >= 0 and nextColumn < columnCount:
        let nextIndex = nextRow * columnCount + nextColumn
        if distances[nextIndex] < 0 and grid[nextRow][nextColumn] != '#':
          distances[nextIndex] = currentDistance + 1
          queue[tailIndex] = nextIndex
          tailIndex += 1
  var distanceTotal: int64 = 0
  var farthestStore = 0
  for storeIndex in storeIndices:
    let storeDistance = distances[storeIndex]
    distanceTotal = distanceTotal + int64(storeDistance)
    if storeDistance > farthestStore:
      farthestStore = storeDistance
  let answer = int64(60 * storeIndices.len) + int64(2) * distanceTotal - int64(farthestStore)
  appendOutput($answer)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0

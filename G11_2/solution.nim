const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const boardSize = 8
const squareCount = 64
const stepX = [1, 2, 2, 1, -1, -2, -2, -1]
const stepY = [2, 1, -1, -2, -2, -1, 1, 2]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

proc squareIndex(token: string): int =
  let column = int(token[0]) - 97
  let row = int(token[1]) - 49
  return row * boardSize + column

var distanceTable: array[squareCount, array[squareCount, int]]
for source in 0..<squareCount:
  for target in 0..<squareCount:
    distanceTable[source][target] = -1
  var visitQueue: array[squareCount, int]
  var queueHead = 0
  var queueTail = 0
  distanceTable[source][source] = 0
  visitQueue[queueTail] = source
  queueTail += 1
  while queueHead < queueTail:
    let current = visitQueue[queueHead]
    queueHead += 1
    let currentRow = current div boardSize
    let currentColumn = current mod boardSize
    let nextDistance = distanceTable[source][current] + 1
    for moveIndex in 0..7:
      let nextRow = currentRow + stepY[moveIndex]
      let nextColumn = currentColumn + stepX[moveIndex]
      if nextRow >= 0 and nextRow < boardSize and nextColumn >= 0 and nextColumn < boardSize:
        let neighbor = nextRow * boardSize + nextColumn
        if distanceTable[source][neighbor] < 0:
          distanceTable[source][neighbor] = nextDistance
          visitQueue[queueTail] = neighbor
          queueTail += 1

var outputBuffer = ""
proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let fromToken = nextToken(inputData, scanPos)
  if fromToken.len == 0: break
  let toToken = nextToken(inputData, scanPos)
  if toToken.len == 0: break
  appendOutput("To get from ")
  appendOutput(fromToken)
  appendOutput(" to ")
  appendOutput(toToken)
  appendOutput(" takes ")
  appendOutput($(distanceTable[squareIndex(fromToken)][squareIndex(toToken)]))
  appendOutput(" knight moves.\n")

stdout.write outputBuffer
outputBuffer.setLen 0

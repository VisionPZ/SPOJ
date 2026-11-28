const flushBlockBytes = 1 shl 17
const unreachableTime = 1 shl 29

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

proc nextDirection(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let direction = data[pos]
  pos += 1
  return direction

proc neighborTime(rowLimit: int, columnLimit: int, startRow: int, startColumn: int,
                  endRow: int, endColumn: int, direction: char): int =
  var neighborRow = endRow
  var neighborColumn = endColumn
  case direction
  of 'U':
    neighborColumn -= 1
  of 'D':
    neighborColumn += 1
  of 'L':
    neighborRow -= 1
  of 'R':
    neighborRow += 1
  else:
    return unreachableTime
  if neighborRow < 0 or neighborRow >= rowLimit or
     neighborColumn < 0 or neighborColumn >= columnLimit:
    return unreachableTime
  return abs(neighborRow - startRow) + abs(neighborColumn - startColumn) + 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let rowLimit = nextInt(inputData, scanPos)
  let columnLimit = nextInt(inputData, scanPos)
  let startRow = nextInt(inputData, scanPos)
  let startColumn = nextInt(inputData, scanPos)
  let endRow = nextInt(inputData, scanPos)
  let endColumn = nextInt(inputData, scanPos)
  let firstDirection = nextDirection(inputData, scanPos)
  let secondDirection = nextDirection(inputData, scanPos)
  let thirdDirection = nextDirection(inputData, scanPos)
  let fourthDirection = nextDirection(inputData, scanPos)
  if startRow == endRow and startColumn == endColumn:
    appendOutput("0")
  else:
    let firstTime = min(neighborTime(rowLimit, columnLimit, startRow, startColumn,
                                     endRow, endColumn, firstDirection),
                        neighborTime(rowLimit, columnLimit, startRow, startColumn,
                                     endRow, endColumn, secondDirection))
    let secondTime = min(neighborTime(rowLimit, columnLimit, startRow, startColumn,
                                      endRow, endColumn, thirdDirection),
                         neighborTime(rowLimit, columnLimit, startRow, startColumn,
                                      endRow, endColumn, fourthDirection))
    if firstTime >= unreachableTime or secondTime >= unreachableTime:
      appendOutput("-1")
    else:
      appendOutput($(firstTime + secondTime))
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0

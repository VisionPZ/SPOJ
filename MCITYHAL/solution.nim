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
  let start = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[start ..< pos]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
var wallRows = newSeq[string](rowCount)
for rowIndex in 0 .. rowCount - 1:
  wallRows[rowIndex] = nextToken(inputData, scanPos)

var runLengthCounts = newSeq[int](rowCount + 1)
for columnIndex in 0 .. columnCount - 1:
  var currentRun = 0
  for rowIndex in 0 .. rowCount - 1:
    if wallRows[rowIndex][columnIndex] == '0':
      currentRun += 1
    else:
      if currentRun > 0:
        runLengthCounts[currentRun] += 1
        currentRun = 0
  if currentRun > 0:
    runLengthCounts[currentRun] += 1

for blockHeight in 1 .. rowCount:
  if runLengthCounts[blockHeight] > 0:
    appendOutput($(blockHeight) & " " & $(runLengthCounts[blockHeight]))
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const positionCapacity = 50005

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

let peopleCount = nextInt(inputData, scanPos)
var isOccupied = newSeq[bool](positionCapacity)
var groupCount = 0
for personIndex in 0 .. peopleCount - 1:
  let position = nextInt(inputData, scanPos)
  var occupiedNeighbors = 0
  if position > 1 and isOccupied[position - 1]:
    occupiedNeighbors += 1
  if position + 1 < positionCapacity and isOccupied[position + 1]:
    occupiedNeighbors += 1
  if occupiedNeighbors == 0:
    groupCount += 1
  elif occupiedNeighbors == 2:
    groupCount -= 1
  isOccupied[position] = true
  appendOutput($groupCount)
  outputBuffer.add '\n'
appendOutput("Justice")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

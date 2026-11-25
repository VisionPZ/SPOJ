const flushBlockBytes = 1 shl 17
const forbiddenEachSide = 2
const minimumLosingCells = 2

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

let caseCount = nextInt(inputData, scanPos)
var cellCounts = newSeq[int](caseCount)
var largestCellCount = 0
for caseIndex in 0 .. caseCount - 1:
  let cellCount = nextInt(inputData, scanPos)
  cellCounts[caseIndex] = cellCount
  if cellCount > largestCellCount:
    largestCellCount = cellCount

var grundyValues = newSeq[int](largestCellCount + 1)
var seenValues = newSeq[bool](largestCellCount + 4)
for cellCount in 1 .. largestCellCount:
  for index in 0 .. seenValues.len - 1:
    seenValues[index] = false
  var position = 1
  while position <= cellCount:
    let leftCells = position - 1 - forbiddenEachSide
    let rightCells = cellCount - position - forbiddenEachSide
    var leftValue = 0
    var rightValue = 0
    if leftCells > 0:
      leftValue = grundyValues[leftCells]
    if rightCells > 0:
      rightValue = grundyValues[rightCells]
    let combined = leftValue xor rightValue
    if combined < seenValues.len:
      seenValues[combined] = true
    position += 1
  var candidate = 0
  while candidate < seenValues.len and seenValues[candidate]:
    candidate += 1
  grundyValues[cellCount] = candidate

for caseIndex in 0 .. caseCount - 1:
  let cellCount = cellCounts[caseIndex]
  if cellCount == minimumLosingCells or (cellCount > minimumLosingCells and grundyValues[cellCount] == 0):
    appendOutput("Bane\n")
  else:
    appendOutput("Joker\n")
stdout.write outputBuffer
outputBuffer.setLen 0

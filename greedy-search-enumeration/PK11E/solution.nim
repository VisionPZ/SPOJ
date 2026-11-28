const flushBlockBytes = 1 shl 17
const sideLimit = 24
const tableLimit = 3000
const markLimit = 4200
const periodSteps: array[0..24, int] = [1, 3, 3, 6, 12, 24, 12, 24, 24, 24, 24, 48, 48, 96, 96, 96, 192, 192, 384, 384, 384, 768, 768, 768, 768]
const preperiodStarts: array[0..24, int] = [0, 0, 0, 8, 9, 27, 37, 92, 102, 127, 224, 277, 347, 382, 613, 693, 771, 865, 919, 1032, 1165, 1252, 1293, 1373, 1732]

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

var grundyTable: array[0..sideLimit, seq[int]]
for sideIndex in 0 .. sideLimit:
  grundyTable[sideIndex] = newSeq[int](tableLimit + 1)

var temporaryMarks = newSeq[int](markLimit + 1)
var permanentMarks = newSeq[bool](markLimit + 1)
var stampCounter = 0
for sideIndex in 0 .. sideLimit:
  for markIndex in 0 .. markLimit:
    permanentMarks[markIndex] = false
  for columnIndex in 0 .. tableLimit:
    stampCounter += 1
    for smallerSide in 0 .. sideIndex - 1:
      temporaryMarks[grundyTable[smallerSide][columnIndex]] = stampCounter
    var diagonalStep = 1
    while diagonalStep <= sideIndex and diagonalStep <= columnIndex:
      temporaryMarks[grundyTable[sideIndex - diagonalStep][columnIndex - diagonalStep]] = stampCounter
      diagonalStep += 1
    var candidateValue = 0
    while permanentMarks[candidateValue] or temporaryMarks[candidateValue] == stampCounter:
      candidateValue += 1
    grundyTable[sideIndex][columnIndex] = candidateValue
    permanentMarks[candidateValue] = true

proc grundyValue(firstPile: int64, secondPile: int64): int64 =
  var smallerPile = firstPile
  var largerPile = secondPile
  if smallerPile > largerPile:
    swap smallerPile, largerPile
  let sideIndex = int(smallerPile)
  if largerPile <= int64(tableLimit):
    return int64(grundyTable[sideIndex][int(largerPile)])
  let periodLength = int64(periodSteps[sideIndex])
  let cycleStart = int64(preperiodStarts[sideIndex])
  let tableIndex = cycleStart + (largerPile - cycleStart) mod periodLength
  return largerPile + int64(grundyTable[sideIndex][int(tableIndex)] - int(tableIndex))

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let queenCount = nextInt(inputData, scanPos)
  var nimSum: int64 = 0
  for queenIndex in 1 .. queenCount:
    let queenRow = int64(nextInt(inputData, scanPos))
    let queenColumn = int64(nextInt(inputData, scanPos))
    nimSum = nimSum xor grundyValue(queenRow - 1, queenColumn - 1)
  if nimSum != 0:
    appendOutput("YES")
  else:
    appendOutput("NO")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

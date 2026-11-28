{.push checks: off.}
{.passC: "-O2".}
import posix

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infinity = high(int) div 4
const maxCities = 100
const maxCells = maxCities * maxCities
const inputChunkBytes = 1 shl 20

var inputData = newString(inputChunkBytes)
var inputLength = 0
while true:
  if inputLength + inputChunkBytes > inputData.len:
    inputData.setLen(inputData.len * 2)
  let bytesRead = read(0, cast[pointer](addr inputData[inputLength]), inputChunkBytes)
  if bytesRead <= 0:
    break
  inputLength += bytesRead
inputData.setLen(inputLength)
inputData.add '!'

var i = 0

proc nextInt(data: string, pos: var int): int {.inline.} =
  while data[pos] <= ' ':
    pos += 1
  var value = 0
  if data[pos] >= '0':
    value = int(data[pos]) - firstDigitValue
    pos += 1
    if data[pos] >= '0':
      value = value * 10 + int(data[pos]) - firstDigitValue
      pos += 1
      if data[pos] >= '0':
        value = value * 10 + int(data[pos]) - firstDigitValue
        pos += 1
        if data[pos] >= '0':
          value = value * 10 + int(data[pos]) - firstDigitValue
          pos += 1
          if data[pos] >= '0':
            value = value * 10 + int(data[pos]) - firstDigitValue
            pos += 1
            while data[pos] >= '0':
              value = value * 10 + int(data[pos]) - firstDigitValue
              pos += 1
  value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var costCells: array[0 .. maxCells - 1, int]

proc maxExchange(rowCount: int, colCount: int): int =
  var rowPotential: array[0 .. maxCities, int]
  var colPotential: array[0 .. maxCities, int]
  var assignedRow: array[0 .. maxCities, int]
  var previousCol: array[0 .. maxCities, int]
  var minReducedCost: array[0 .. maxCities, int]
  var visitedMark: array[0 .. maxCities, int]
  var generation = 0
  for r in 1..rowCount:
    assignedRow[0] = r
    generation += 1
    for k in 0..colCount:
      minReducedCost[k] = infinity
    var currentCol = 0
    while true:
      visitedMark[currentCol] = generation
      let currentRow = assignedRow[currentCol]
      let rowBase = (currentRow - 1) * colCount
      var delta = infinity
      var nextCol = 0
      for k in 1..colCount:
        if visitedMark[k] != generation:
          let reducedCost = costCells[rowBase + k - 1] -
                            rowPotential[currentRow] - colPotential[k]
          if reducedCost < minReducedCost[k]:
            minReducedCost[k] = reducedCost
            previousCol[k] = currentCol
          if minReducedCost[k] < delta:
            delta = minReducedCost[k]
            nextCol = k
      for k in 0..colCount:
        if visitedMark[k] == generation:
          rowPotential[assignedRow[k]] += delta
          colPotential[k] -= delta
        else:
          minReducedCost[k] -= delta
      currentCol = nextCol
      if assignedRow[currentCol] == 0:
        break
    while true:
      let backCol = previousCol[currentCol]
      assignedRow[currentCol] = assignedRow[backCol]
      currentCol = backCol
      if currentCol == 0:
        break
  var totalCost = 0
  for k in 1..colCount:
    if assignedRow[k] != 0:
      totalCost += costCells[(assignedRow[k] - 1) * colCount + k - 1]
  -totalCost

let caseCount = nextInt(inputData, i)
for caseIndex in 0..<caseCount:
  let sellerCount = nextInt(inputData, i)
  let buyerCount = nextInt(inputData, i)
  let transposed = sellerCount > buyerCount
  let rowCount = if transposed: buyerCount else: sellerCount
  let colCount = if transposed: sellerCount else: buyerCount
  let cellCount = rowCount * colCount
  for k in 0..<cellCount:
    costCells[k] = 0
  while true:
    let fromCity = nextInt(inputData, i)
    let toCity = nextInt(inputData, i)
    let goods = nextInt(inputData, i)
    if fromCity == 0 and toCity == 0 and goods == 0:
      break
    if fromCity >= 1 and fromCity <= sellerCount and toCity >= 1 and toCity <= buyerCount:
      let rowIndex = if transposed: toCity - 1 else: fromCity - 1
      let colIndex = if transposed: fromCity - 1 else: toCity - 1
      let cellIndex = rowIndex * colCount + colIndex
      if -goods < costCells[cellIndex]:
        costCells[cellIndex] = -goods
  let answer = maxExchange(rowCount, colCount)
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

{.pop.}

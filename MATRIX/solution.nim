const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maximumDimension = 200
const noValueYet = -1000000000

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc considerCandidate(candidateValue: int, candidateCount: int64,
                       bestValue: var int, bestCount: var int64) =
  if candidateValue > bestValue:
    bestValue = candidateValue
    bestCount = candidateCount
  elif candidateValue == bestValue:
    bestCount += candidateCount

var cellValue = newSeq[int](maximumDimension * maximumDimension)
var colPrefix = newSeq[int]((maximumDimension + 1) * maximumDimension)
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  for columnIndex in 0..<columnCount:
    colPrefix[columnIndex] = 0
  for rowIndex in 0..<rowCount:
    for columnIndex in 0..<columnCount:
      let inputDigit = nextInt(inputData, scanPos)
      cellValue[rowIndex * columnCount + columnIndex] = inputDigit * 2 - 1
  for rowIndex in 0..<rowCount:
    for columnIndex in 0..<columnCount:
      colPrefix[(rowIndex + 1) * columnCount + columnIndex] =
        colPrefix[rowIndex * columnCount + columnIndex] +
        cellValue[rowIndex * columnCount + columnIndex]
  var bestValue = noValueYet
  var bestCount: int64 = 0
  for rowIndex in 0..<rowCount:
    var prefixSum = 0
    var minPrefix = 0
    var minCount: int64 = 0
    for columnIndex in 0..<columnCount:
      if prefixSum < minPrefix:
        minPrefix = prefixSum
        minCount = 1
      elif prefixSum == minPrefix:
        minCount += 1
      prefixSum += cellValue[rowIndex * columnCount + columnIndex]
      considerCandidate(prefixSum - minPrefix, minCount, bestValue, bestCount)
  for topRow in 0..<(rowCount - 1):
    for bottomRow in (topRow + 1)..<rowCount:
      var segmentSum = 0
      var runningMax = noValueYet
      var runningCount: int64 = 0
      for columnIndex in 0..<columnCount:
        let topBottom = cellValue[topRow * columnCount + columnIndex] +
                        cellValue[bottomRow * columnCount + columnIndex]
        let middle = colPrefix[bottomRow * columnCount + columnIndex] -
                     colPrefix[(topRow + 1) * columnCount + columnIndex]
        let leftValue = middle - segmentSum
        segmentSum += topBottom
        let rightValue = segmentSum + middle
        if columnIndex > 0:
          considerCandidate(runningMax + rightValue, runningCount,
                            bestValue, bestCount)
        considerCandidate(topBottom + middle, int64(1), bestValue, bestCount)
        if leftValue > runningMax:
          runningMax = leftValue
          runningCount = 1
        elif leftValue == runningMax:
          runningCount += 1
  appendOutput($(bestValue) & " " & $(bestCount) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0

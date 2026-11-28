const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const maxPlaceCount = 200
const matrixStride = maxPlaceCount + 1
const impossibleCost = int64(1 shl 50)

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add "\n"

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and data[scanPos] <= ' ':
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value

var costMatrix = newSeq[int64](matrixStride * matrixStride)
var rowPotential = newSeq[int64](matrixStride)
var colPotential = newSeq[int64](matrixStride)
var columnOwner = newSeq[int](matrixStride)
var parentColumn = newSeq[int](matrixStride)
var minExtraCost = newSeq[int64](matrixStride)
var usedColumn = newSeq[bool](matrixStride)

proc minimumCoverCost(placeCount: int): int64 =
  for row in 0 .. placeCount:
    rowPotential[row] = 0
    colPotential[row] = 0
    columnOwner[row] = 0
  for freeRow in 1 .. placeCount:
    columnOwner[0] = freeRow
    var currentColumn = 0
    for column in 0 .. placeCount:
      usedColumn[column] = false
      minExtraCost[column] = impossibleCost
      parentColumn[column] = 0
    while true:
      usedColumn[currentColumn] = true
      let sourceRow = columnOwner[currentColumn]
      let sourceBase = sourceRow * matrixStride
      let sourcePotential = rowPotential[sourceRow]
      var smallestDelta = impossibleCost
      var nextColumn = 0
      for column in 1 .. placeCount:
        if not usedColumn[column]:
          let reducedCost = costMatrix[sourceBase + column] - sourcePotential - colPotential[column]
          if reducedCost < minExtraCost[column]:
            minExtraCost[column] = reducedCost
            parentColumn[column] = currentColumn
          if minExtraCost[column] < smallestDelta:
            smallestDelta = minExtraCost[column]
            nextColumn = column
      for column in 0 .. placeCount:
        if usedColumn[column]:
          rowPotential[columnOwner[column]] += smallestDelta
          colPotential[column] -= smallestDelta
        else:
          minExtraCost[column] -= smallestDelta
      currentColumn = nextColumn
      if columnOwner[currentColumn] == 0: break
    while currentColumn != 0:
      let priorColumn = parentColumn[currentColumn]
      columnOwner[currentColumn] = columnOwner[priorColumn]
      currentColumn = priorColumn
  return -colPotential[0]

var outputBuffer = ""
var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let placeCount = nextInt(inputData, scanPos)
  let streetCount = nextInt(inputData, scanPos)
  for row in 0 .. placeCount:
    let rowBase = row * matrixStride
    for column in 0 .. placeCount:
      costMatrix[rowBase + column] = impossibleCost
  for streetIndex in 0 ..< streetCount:
    let fromPlace = nextInt(inputData, scanPos)
    let toPlace = nextInt(inputData, scanPos)
    let streetLength = int64(nextInt(inputData, scanPos))
    let position = fromPlace * matrixStride + toPlace
    if streetLength < costMatrix[position]:
      costMatrix[position] = streetLength
  outputBuffer.add $(minimumCoverCost(placeCount))
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer

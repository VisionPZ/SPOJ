const flushBlockBytes = 1 shl 17
const answerModulus = 1000000007
const maxWeight = 3

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

proc nextAdjacencyRow(data: string, pos: var int, width: int): string =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  result = ""
  var taken = 0
  while taken < width and pos < data.len:
    result.add data[pos]
    pos += 1
    taken += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc multiplyMatrices(leftMatrix: seq[int64], rightMatrix: seq[int64], dimension: int): seq[int64] =
  var productMatrix = newSeq[int64](dimension * dimension)
  var rowIndex = 0
  while rowIndex < dimension:
    var columnIndex = 0
    while columnIndex < dimension:
      var total = int64(0)
      var middleIndex = 0
      while middleIndex < dimension:
        total = (total + leftMatrix[rowIndex * dimension + middleIndex] * rightMatrix[middleIndex * dimension + columnIndex]) mod answerModulus
        middleIndex += 1
      productMatrix[rowIndex * dimension + columnIndex] = total
      columnIndex += 1
    rowIndex += 1
  return productMatrix

let caseTotal = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseTotal - 1:
  let vertexCount = nextInt(inputData, scanPos)
  let timeLimit = int64(nextInt(inputData, scanPos))
  let stateSize = vertexCount * maxWeight + 1
  let prefixIndex = stateSize - 1
  var transitionMatrix = newSeq[int64](stateSize * stateSize)
  var sourceVertex = 0
  while sourceVertex < vertexCount:
    let adjacencyRow = nextAdjacencyRow(inputData, scanPos, vertexCount)
    var targetVertex = 0
    while targetVertex < vertexCount:
      let roadCharacter = adjacencyRow[targetVertex]
      if roadCharacter >= '1' and roadCharacter <= '3':
        let roadWeight = int(roadCharacter) - 48
        let historyRow = (roadWeight - 1) * vertexCount + sourceVertex
        transitionMatrix[targetVertex * stateSize + historyRow] = (transitionMatrix[targetVertex * stateSize + historyRow] + 1) mod answerModulus
        if targetVertex == 1:
          transitionMatrix[prefixIndex * stateSize + historyRow] = (transitionMatrix[prefixIndex * stateSize + historyRow] + 1) mod answerModulus
      targetVertex += 1
    sourceVertex += 1
  var previousVertex = 0
  while previousVertex < vertexCount:
    let firstShiftRow = vertexCount + previousVertex
    let secondShiftRow = 2 * vertexCount + previousVertex
    transitionMatrix[firstShiftRow * stateSize + previousVertex] = 1
    transitionMatrix[secondShiftRow * stateSize + vertexCount + previousVertex] = 1
    previousVertex += 1
  transitionMatrix[prefixIndex * stateSize + prefixIndex] = 1
  var stateVector = newSeq[int64](stateSize)
  stateVector[0] = 1
  var remainingTime = timeLimit
  while remainingTime > 0:
    if (remainingTime and 1) == 1:
      var nextVector = newSeq[int64](stateSize)
      var rowIndex = 0
      while rowIndex < stateSize:
        var total = int64(0)
        var columnIndex = 0
        while columnIndex < stateSize:
          total = (total + transitionMatrix[rowIndex * stateSize + columnIndex] * stateVector[columnIndex]) mod answerModulus
          columnIndex += 1
        nextVector[rowIndex] = total
        rowIndex += 1
      stateVector = nextVector
    transitionMatrix = multiplyMatrices(transitionMatrix, transitionMatrix, stateSize)
    remainingTime = remainingTime shr 1
  appendOutput("Case #" & $(caseIndex + 1) & ": " & $stateVector[prefixIndex] & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0

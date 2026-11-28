const hashBase: uint64 = 257
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
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

proc signatureHash(counts: array[26, int]): uint64 =
  var hashValue: uint64 = 0
  for letterIndex in 0 .. 25:
    hashValue = hashValue * hashBase + uint64(counts[letterIndex])
  return hashValue

proc rowSignature(text: string): uint64 =
  var counts: array[26, int]
  for letterIndex in 0 .. 25:
    counts[letterIndex] = 0
  for textIndex in 0 .. text.len - 1:
    counts[int(text[textIndex]) - 97] += 1
  return signatureHash(counts)

proc buildPrefix(values: seq[uint64], count: int): seq[uint64] =
  result = newSeq[uint64](count + 1)
  result[0] = 0
  for indexValue in 0 .. count - 1:
    result[indexValue + 1] = result[indexValue] * hashBase + values[indexValue]
  return result

proc rangeHash(prefix: seq[uint64], powers: seq[uint64], leftIndex, rightIndex: int): uint64 =
  return prefix[rightIndex] - prefix[leftIndex] * powers[rightIndex - leftIndex]

proc matchesTransform(sourceGrid: seq[string], targetGrid: seq[string], rowCut, leftCut, rightCut, size: int): bool =
  for targetRow in 0 .. size - 1:
    let sourceRow = if targetRow <= rowCut: rowCut - targetRow else: targetRow
    for targetColumn in 0 .. size - 1:
      let rotatedIndex = (targetColumn + leftCut + 1) mod size
      var suffixIndex = rotatedIndex
      if rotatedIndex >= rightCut:
        suffixIndex = size + rightCut - 1 - rotatedIndex
      let sourceColumn = if suffixIndex <= leftCut: leftCut - suffixIndex else: suffixIndex
      if sourceGrid[sourceRow][sourceColumn] != targetGrid[targetRow][targetColumn]:
        return false
  return true

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let gridSize = nextInt(inputData, scanPos)
var sourceGrid = newSeq[string](gridSize)
var targetGrid = newSeq[string](gridSize)
for rowIndex in 0 .. gridSize - 1:
  sourceGrid[rowIndex] = nextToken(inputData, scanPos)
for rowIndex in 0 .. gridSize - 1:
  targetGrid[rowIndex] = nextToken(inputData, scanPos)

var sourceRowSignatures = newSeq[uint64](gridSize)
var targetRowSignatures = newSeq[uint64](gridSize)
for rowIndex in 0 .. gridSize - 1:
  sourceRowSignatures[rowIndex] = rowSignature(sourceGrid[rowIndex])
  targetRowSignatures[rowIndex] = rowSignature(targetGrid[rowIndex])

var rowCandidates: seq[int] = @[]
for rowCut in countDown(gridSize - 2, 1):
  var agree = true
  for targetRow in 0 .. gridSize - 1:
    let sourceRow = if targetRow <= rowCut: rowCut - targetRow else: targetRow
    if sourceRowSignatures[sourceRow] != targetRowSignatures[targetRow]:
      agree = false
      break
  if agree:
    rowCandidates.add rowCut

var sourceColumnSignatures = newSeq[uint64](gridSize)
var targetColumnSignatures = newSeq[uint64](gridSize)
var reversedSourceSignatures = newSeq[uint64](gridSize)
for columnIndex in 0 .. gridSize - 1:
  var counts: array[26, int]
  for letterIndex in 0 .. 25:
    counts[letterIndex] = 0
  for rowIndex in 0 .. gridSize - 1:
    counts[int(sourceGrid[rowIndex][columnIndex]) - 97] += 1
  sourceColumnSignatures[columnIndex] = signatureHash(counts)
for columnIndex in 0 .. gridSize - 1:
  var counts: array[26, int]
  for letterIndex in 0 .. 25:
    counts[letterIndex] = 0
  for rowIndex in 0 .. gridSize - 1:
    counts[int(targetGrid[rowIndex][columnIndex]) - 97] += 1
  targetColumnSignatures[columnIndex] = signatureHash(counts)
for columnIndex in 0 .. gridSize - 1:
  reversedSourceSignatures[gridSize - 1 - columnIndex] = sourceColumnSignatures[columnIndex]

var powers = newSeq[uint64](gridSize + 1)
powers[0] = 1
for indexValue in 1 .. gridSize:
  powers[indexValue] = powers[indexValue - 1] * hashBase
var sourcePrefix = buildPrefix(sourceColumnSignatures, gridSize)
var targetPrefix = buildPrefix(targetColumnSignatures, gridSize)
var reversedPrefix = buildPrefix(reversedSourceSignatures, gridSize)

var leftCandidates: seq[int] = @[]
var rightCandidates: seq[int] = @[]
for leftCut in countDown(gridSize - 2, 0):
  if rangeHash(targetPrefix, powers, gridSize - leftCut - 1, gridSize) !=
      rangeHash(reversedPrefix, powers, gridSize - 1 - leftCut, gridSize):
    continue
  for rightCut in countDown(gridSize - 1, leftCut + 1):
    let middleLength = rightCut - leftCut - 1
    if rangeHash(targetPrefix, powers, 0, middleLength) !=
        rangeHash(sourcePrefix, powers, leftCut + 1, rightCut):
      continue
    if rangeHash(targetPrefix, powers, middleLength, gridSize - leftCut - 1) !=
        rangeHash(reversedPrefix, powers, 0, gridSize - rightCut):
      continue
    leftCandidates.add leftCut
    rightCandidates.add rightCut

var answerFound = false
for rowIndex in 0 .. rowCandidates.len - 1:
  if answerFound:
    break
  let rowCut = rowCandidates[rowIndex]
  for pairIndex in 0 .. leftCandidates.len - 1:
    let leftCut = leftCandidates[pairIndex]
    let rightCut = rightCandidates[pairIndex]
    if matchesTransform(sourceGrid, targetGrid, rowCut, leftCut, rightCut, gridSize):
      appendOutput($rowCut & " " & $leftCut & " " & $rightCut)
      outputBuffer.add '\n'
      answerFound = true
      break
stdout.write outputBuffer
outputBuffer.setLen 0

import sequtils

const flushBlockBytes = 1 shl 17
const alphabetSize = 26
const moduloBase = 10007

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < 'A' or data[pos] > 'Z'):
    pos += 1
  result = ""
  while pos < data.len and data[pos] >= 'A' and data[pos] <= 'Z':
    result.add data[pos]
    pos += 1

proc hasDigits(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len:
    if data[cursor] >= '0' and data[cursor] <= '9':
      return true
    cursor += 1
  return false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc multiplyMatrices(left: seq[int], size: int): seq[int] =
  result = newSeq[int](size * size)
  for rowIndex in 0 .. size - 1:
    for middleIndex in 0 .. size - 1:
      let leftValue = left[rowIndex * size + middleIndex]
      if leftValue == 0:
        continue
      for columnIndex in 0 .. size - 1:
        let rightValue = left[middleIndex * size + columnIndex]
        if rightValue == 0:
          continue
        let cellIndex = rowIndex * size + columnIndex
        result[cellIndex] = (result[cellIndex] + leftValue * rightValue) mod moduloBase
  return result

proc multiplyVectorMatrix(stateVector: seq[int], matrix: seq[int], size: int): seq[int] =
  result = newSeq[int](size)
  for columnIndex in 0 .. size - 1:
    var total: int64 = 0
    for rowIndex in 0 .. size - 1:
      total += int64(stateVector[rowIndex]) * int64(matrix[rowIndex * size + columnIndex])
    result[columnIndex] = int(total mod int64(moduloBase))
  return result

while hasDigits(inputData, scanPos):
  let wordCount = nextInt(inputData, scanPos)
  let articleLength = nextInt(inputData, scanPos)
  var transitionTable: seq[seq[int]] = @[]
  var failLinks: seq[int] = @[]
  var wordEnds: seq[bool] = @[]
  transitionTable.add repeat(-1, alphabetSize)
  failLinks.add 0
  wordEnds.add false
  for wordIndex in 0 .. wordCount - 1:
    let knownWord = nextWord(inputData, scanPos)
    var nodeIndex = 0
    for character in knownWord:
      let letterIndex = int(character) - 65
      if transitionTable[nodeIndex][letterIndex] == -1:
        transitionTable[nodeIndex][letterIndex] = transitionTable.len
        transitionTable.add repeat(-1, alphabetSize)
        failLinks.add 0
        wordEnds.add false
      nodeIndex = transitionTable[nodeIndex][letterIndex]
    wordEnds[nodeIndex] = true
  var automatonQueue: seq[int] = @[]
  for letterIndex in 0 .. alphabetSize - 1:
    let childNode = transitionTable[0][letterIndex]
    if childNode == -1:
      transitionTable[0][letterIndex] = 0
    else:
      failLinks[childNode] = 0
      automatonQueue.add childNode
  var queueFront = 0
  while queueFront < automatonQueue.len:
    let nodeIndex = automatonQueue[queueFront]
    queueFront += 1
    if wordEnds[failLinks[nodeIndex]]:
      wordEnds[nodeIndex] = true
    for letterIndex in 0 .. alphabetSize - 1:
      let childNode = transitionTable[nodeIndex][letterIndex]
      if childNode == -1:
        transitionTable[nodeIndex][letterIndex] = transitionTable[failLinks[nodeIndex]][letterIndex]
      else:
        failLinks[childNode] = transitionTable[failLinks[nodeIndex]][letterIndex]
        automatonQueue.add childNode
  let stateCount = transitionTable.len
  let matrixSize = stateCount + 1
  var transitionMatrix = newSeq[int](matrixSize * matrixSize)
  for stateIndex in 0 .. stateCount - 1:
    if wordEnds[stateIndex]:
      continue
    for letterIndex in 0 .. alphabetSize - 1:
      let destination = transitionTable[stateIndex][letterIndex]
      if wordEnds[destination]:
        transitionMatrix[stateIndex * matrixSize + stateCount] += 1
      else:
        transitionMatrix[stateIndex * matrixSize + destination] += 1
  transitionMatrix[stateCount * matrixSize + stateCount] = alphabetSize
  var stateVector = newSeq[int](matrixSize)
  stateVector[0] = 1
  var remainingLength = articleLength
  while remainingLength > 0:
    if (remainingLength and 1) != 0:
      stateVector = multiplyVectorMatrix(stateVector, transitionMatrix, matrixSize)
    remainingLength = remainingLength shr 1
    if remainingLength > 0:
      transitionMatrix = multiplyMatrices(transitionMatrix, matrixSize)
  appendOutput($stateVector[stateCount])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

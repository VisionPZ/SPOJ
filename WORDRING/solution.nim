const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const letterOffset = 97
const alphabetSize = 26
const vertexCount = alphabetSize * alphabetSize
const unreachableScore = -1 shl 50
const hugeAnswer = 1e50

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc letterCode(letter: char): int =
  return int(letter) - letterOffset

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendAverage(average: float) =
  let scaledValue = int64(average * 100.0)
  let wholePart = scaledValue div 100
  let fractionPart = scaledValue mod 100
  if fractionPart < 10:
    appendOutput($wholePart & ".0" & $fractionPart)
  else:
    appendOutput($wholePart & "." & $fractionPart)

while true:
  let wordCount = nextInt(inputData, scanPos)
  if wordCount == 0:
    break
  var edgeFrom = newSeq[int](wordCount)
  var edgeTo = newSeq[int](wordCount)
  var edgeLength = newSeq[int](wordCount)
  var edgeCount = 0
  for wordIndex in 0 .. wordCount - 1:
    while scanPos < inputData.len and inputData[scanPos] <= ' ':
      scanPos += 1
    let wordStart = scanPos
    while scanPos < inputData.len and inputData[scanPos] > ' ':
      scanPos += 1
    let currentLength = scanPos - wordStart
    var sourceCode = 0
    var targetCode = 0
    if currentLength == 1:
      sourceCode = letterCode(inputData[wordStart]) * alphabetSize + letterCode(inputData[wordStart])
      targetCode = sourceCode
    else:
      sourceCode = letterCode(inputData[wordStart]) * alphabetSize +
        letterCode(inputData[wordStart + 1])
      targetCode = letterCode(inputData[wordStart + currentLength - 2]) * alphabetSize +
        letterCode(inputData[wordStart + currentLength - 1])
    edgeFrom[edgeCount] = sourceCode
    edgeTo[edgeCount] = targetCode
    edgeLength[edgeCount] = currentLength
    edgeCount += 1
  var scores = newSeq[int]((vertexCount + 1) * vertexCount)
  for position in vertexCount .. (vertexCount + 1) * vertexCount - 1:
    scores[position] = unreachableScore
  for pathLength in 1 .. vertexCount:
    let previousOffset = (pathLength - 1) * vertexCount
    let currentOffset = pathLength * vertexCount
    for edgeIndex in 0 .. edgeCount - 1:
      let sourceScore = scores[previousOffset + edgeFrom[edgeIndex]]
      if sourceScore > unreachableScore:
        let candidate = sourceScore + edgeLength[edgeIndex]
        let targetPosition = currentOffset + edgeTo[edgeIndex]
        if candidate > scores[targetPosition]:
          scores[targetPosition] = candidate
  var bestAverage = -hugeAnswer
  for targetVertex in 0 .. vertexCount - 1:
    let finalScore = scores[vertexCount * vertexCount + targetVertex]
    if finalScore == unreachableScore:
      continue
    var vertexBest = hugeAnswer
    for pathLength in 0 .. vertexCount - 1:
      let earlierScore = scores[pathLength * vertexCount + targetVertex]
      if earlierScore == unreachableScore:
        continue
      let candidateAverage = float(finalScore - earlierScore) /
        float(vertexCount - pathLength)
      if candidateAverage < vertexBest:
        vertexBest = candidateAverage
    if vertexBest > bestAverage:
      bestAverage = vertexBest
  if bestAverage <= -hugeAnswer / 2.0:
    appendOutput("No solution.")
  else:
    appendAverage(bestAverage)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

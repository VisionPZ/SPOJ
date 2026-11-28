const flushBlockBytes = 1 shl 17
const stateCount = 4
const impossibleCost = 1000000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var insertDist = newSeq[seq[int]](stateCount)
var distanceCursor = 0
while distanceCursor < stateCount:
  insertDist[distanceCursor] = newSeq[int](stateCount)
  var targetCursor = 0
  while targetCursor < stateCount:
    if distanceCursor == targetCursor:
      insertDist[distanceCursor][targetCursor] = 0
    else:
      insertDist[distanceCursor][targetCursor] = impossibleCost
    targetCursor += 1
  distanceCursor += 1
insertDist[0][1] = 1
insertDist[0][3] = 1
insertDist[1][2] = 1
insertDist[2][0] = 1
insertDist[3][0] = 1
var middleCursor = 0
while middleCursor < stateCount:
  var fromCursor = 0
  while fromCursor < stateCount:
    var toCursor = 0
    while toCursor < stateCount:
      let candidate = insertDist[fromCursor][middleCursor] + insertDist[middleCursor][toCursor]
      if candidate < insertDist[fromCursor][toCursor]:
        insertDist[fromCursor][toCursor] = candidate
      toCursor += 1
    fromCursor += 1
  middleCursor += 1

var patternText = ""
var charCursor = 0
while charCursor < inputData.len:
  let currentChar = inputData[charCursor]
  if currentChar == 'P' or currentChar == 'A' or currentChar == 'N' or currentChar == 'D':
    patternText.add currentChar
  charCursor += 1

var stateCost: array[stateCount, int] = [0, impossibleCost, impossibleCost, impossibleCost]
for patternChar in patternText:
  var relaxed: array[stateCount, int]
  var targetCursor = 0
  while targetCursor < stateCount:
    relaxed[targetCursor] = impossibleCost
    var fromCursor = 0
    while fromCursor < stateCount:
      let candidate = stateCost[fromCursor] + insertDist[fromCursor][targetCursor]
      if candidate < relaxed[targetCursor]:
        relaxed[targetCursor] = candidate
      fromCursor += 1
    targetCursor += 1
  var nextCost: array[stateCount, int] = [impossibleCost, impossibleCost, impossibleCost, impossibleCost]
  case patternChar
  of 'P':
    nextCost[1] = relaxed[0]
  of 'A':
    nextCost[2] = relaxed[1]
    if relaxed[3] < nextCost[0]:
      nextCost[0] = relaxed[3]
  of 'N':
    nextCost[0] = relaxed[2]
  of 'D':
    nextCost[3] = relaxed[0]
  else:
    discard
  stateCost = nextCost

var answer = impossibleCost
var finalCursor = 0
while finalCursor < stateCount:
  let candidate = stateCost[finalCursor] + insertDist[finalCursor][0]
  if candidate < answer:
    answer = candidate
  finalCursor += 1
appendOutput($answer & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0

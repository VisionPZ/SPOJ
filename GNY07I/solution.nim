const flushBlockBytes = 1 shl 17
const cornerFaceIndices: array[8, array[3, int]] = [
  [0, 2, 1], [0, 3, 2], [0, 4, 3], [0, 1, 4],
  [5, 1, 2], [5, 2, 3], [5, 3, 4], [5, 4, 1]]
const cornerTurnShifts: array[8, array[3, int]] = [
  [1, 0, 3], [2, 0, 3], [3, 0, 3], [0, 0, 3],
  [0, 2, 1], [3, 2, 1], [2, 2, 1], [1, 2, 1]]

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

proc nextPair(data: string, pos: var int): tuple[image: int, turn: int] =
  while pos < data.len and (data[pos] < 'A' or data[pos] > 'F'):
    pos += 1
  let image = int(data[pos]) - 65
  pos += 1
  let turn = int(data[pos]) - 49
  pos += 1
  return (image, turn)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  var flatImages: array[6, int]
  var flatTurns: array[6, int]
  for faceIndex in 0 .. 5:
    let pair = nextPair(inputData, scanPos)
    flatImages[faceIndex] = pair.image
    flatTurns[faceIndex] = pair.turn
  var cornerImages: array[8, array[3, int]]
  var cornerTurns: array[8, array[3, int]]
  for corner in 0 .. 7:
    for slot in 0 .. 2:
      let faceIndex = cornerFaceIndices[corner][slot]
      cornerImages[corner][slot] = flatImages[faceIndex]
      cornerTurns[corner][slot] = (flatTurns[faceIndex] + cornerTurnShifts[corner][slot]) mod 4
  var verdicts = ""
  var solutionCount = 0
  for answerIndex in 0 .. 4:
    var answerImages: array[3, int]
    var answerTurns: array[3, int]
    for slot in 0 .. 2:
      let pair = nextPair(inputData, scanPos)
      answerImages[slot] = pair.image
      answerTurns[slot] = pair.turn
    var matched = false
    block search:
      for corner in 0 .. 7:
        for rotation in 0 .. 2:
          var agrees = true
          for slot in 0 .. 2:
            let target = (rotation + slot) mod 3
            if cornerImages[corner][target] != answerImages[slot] or cornerTurns[corner][target] != answerTurns[slot]:
              agrees = false
              break
          if agrees:
            matched = true
            break search
    if matched:
      solutionCount += 1
      verdicts.add 'Y'
    else:
      verdicts.add 'N'
  appendOutput($(caseIndex))
  outputBuffer.add ' '
  appendOutput($(solutionCount))
  for answerIndex in 0 .. 4:
    outputBuffer.add ' '
    outputBuffer.add verdicts[answerIndex]
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

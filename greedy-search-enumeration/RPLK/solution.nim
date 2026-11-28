const flushBlockBytes = 1 shl 17

type WoodPiece = object
  height: int
  width: int

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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let pieceCount = nextInt(inputData, scanPos)
  let overlap = nextInt(inputData, scanPos)
  let separatorHeight = nextInt(inputData, scanPos)
  let maxSteps = nextInt(inputData, scanPos)
  let stepWidth = overlap + 1
  var pieces: seq[WoodPiece] = @[]
  var largestValue = 0
  for pieceIndex in 1 .. pieceCount:
    var piece: WoodPiece
    piece.height = nextInt(inputData, scanPos)
    piece.width = nextInt(inputData, scanPos)
    pieces.add piece
    let candidateValue = piece.height + separatorHeight
    if candidateValue > largestValue:
      largestValue = candidateValue
  var buckets = newSeq[int](largestValue + 1)
  for pieceIndex in 0 .. pieces.len - 1:
    let piece = pieces[pieceIndex]
    let stepCount = piece.width div stepWidth
    if stepCount > 0:
      buckets[piece.height + separatorHeight] += stepCount
  var remainingSteps = maxSteps
  var totalHeight: int64 = 0
  var valueCursor = largestValue
  while valueCursor >= 0 and remainingSteps > 0:
    let takenSteps = buckets[valueCursor]
    if takenSteps > 0:
      if takenSteps > remainingSteps:
        totalHeight += int64(valueCursor) * int64(remainingSteps)
        remainingSteps = 0
      else:
        totalHeight += int64(valueCursor) * int64(takenSteps)
        remainingSteps -= takenSteps
    valueCursor -= 1
  appendOutput("Scenario #")
  appendOutput($caseIndex)
  appendOutput(": ")
  appendOutput($totalHeight)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

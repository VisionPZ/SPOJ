const flushBlockBytes = 1 shl 17
const maxLabel = 100000

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

let ballCount = nextInt(inputData, scanPos)
let requiredCount = (ballCount + 1) div 2
var topCounts = newSeq[int](maxLabel + 1)
var bottomCounts = newSeq[int](maxLabel + 1)
var bothCounts = newSeq[int](maxLabel + 1)
var ballIndex = 0
while ballIndex < ballCount:
  let topLabel = nextInt(inputData, scanPos)
  let bottomLabel = nextInt(inputData, scanPos)
  topCounts[topLabel] += 1
  bottomCounts[bottomLabel] += 1
  if topLabel == bottomLabel:
    bothCounts[topLabel] += 1
  ballIndex += 1
var bestMoves = ballCount + 1
var label = 0
while label <= maxLabel:
  let freeCount = topCounts[label]
  let flippableCount = bottomCounts[label] - bothCounts[label]
  if freeCount + flippableCount >= requiredCount:
    var neededMoves = requiredCount - freeCount
    if neededMoves < 0:
      neededMoves = 0
    if neededMoves <= flippableCount and neededMoves < bestMoves:
      bestMoves = neededMoves
  label += 1
if bestMoves <= ballCount:
  appendOutput($bestMoves)
else:
  appendOutput("Impossible")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const maxPaintings = 200

proc nextInt(inputData: string, scanPosition: var int): int =
  while scanPosition < inputData.len and (inputData[scanPosition] < '0' or inputData[scanPosition] > '9'):
    scanPosition += 1
  var value = 0
  while scanPosition < inputData.len and inputData[scanPosition] >= '0' and inputData[scanPosition] <= '9':
    value = value * 10 + int(inputData[scanPosition]) - firstDigitValue
    scanPosition += 1
  return value

proc sortAscending(values: var seq[int]) =
  for i in 1 .. values.len - 1:
    let key = values[i]
    var j = i - 1
    while j >= 0 and values[j] > key:
      values[j + 1] = values[j]
      j -= 1
    values[j + 1] = key

proc removeDuplicates(values: var seq[int]) =
  if values.len == 0: return
  var writePos = 1
  for i in 1 .. values.len - 1:
    if values[i] != values[writePos - 1]:
      values[writePos] = values[i]
      writePos += 1
  values.setLen writePos

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

var leftEdge: array[maxPaintings, int]
var bottomEdge: array[maxPaintings, int]
var rightEdge: array[maxPaintings, int]
var topEdge: array[maxPaintings, int]
var leftOrder: array[maxPaintings, int]
var activeLeft: array[maxPaintings, int]
var activeRight: array[maxPaintings, int]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let paintingCount = nextInt(inputData, scanPos)
  let wallWidth = nextInt(inputData, scanPos)
  let wallHeight = nextInt(inputData, scanPos)
  for paintingIndex in 0 .. paintingCount - 1:
    leftEdge[paintingIndex] = nextInt(inputData, scanPos)
    bottomEdge[paintingIndex] = nextInt(inputData, scanPos)
    rightEdge[paintingIndex] = nextInt(inputData, scanPos)
    topEdge[paintingIndex] = nextInt(inputData, scanPos)
  let newWidth = nextInt(inputData, scanPos)
  let newHeight = nextInt(inputData, scanPos)
  let maxPlaceX = wallWidth - newWidth
  let maxPlaceY = wallHeight - newHeight

  var xCandidates: seq[int]
  var yCandidates: seq[int]
  xCandidates.add 0
  yCandidates.add 0
  for paintingIndex in 0 .. paintingCount - 1:
    if rightEdge[paintingIndex] <= maxPlaceX: xCandidates.add rightEdge[paintingIndex]
    if topEdge[paintingIndex] <= maxPlaceY: yCandidates.add topEdge[paintingIndex]
  sortAscending(xCandidates)
  sortAscending(yCandidates)
  removeDuplicates(xCandidates)
  removeDuplicates(yCandidates)

  for paintingIndex in 0 .. paintingCount - 1:
    leftOrder[paintingIndex] = paintingIndex
  for i in 1 .. paintingCount - 1:
    let key = leftOrder[i]
    var j = i - 1
    while j >= 0 and leftEdge[leftOrder[j]] > leftEdge[key]:
      leftOrder[j + 1] = leftOrder[j]
      j -= 1
    leftOrder[j + 1] = key

  var placed = false
  for candidateY in yCandidates:
    var activeCount = 0
    for k in 0 .. paintingCount - 1:
      let paintingIndex = leftOrder[k]
      if candidateY < topEdge[paintingIndex] and candidateY + newHeight > bottomEdge[paintingIndex]:
        activeLeft[activeCount] = leftEdge[paintingIndex] - newWidth
        activeRight[activeCount] = rightEdge[paintingIndex]
        activeCount += 1
    var maxBlockedRight = -1
    var activePos = 0
    for candidateX in xCandidates:
      while activePos < activeCount and activeLeft[activePos] < candidateX:
        if activeRight[activePos] > maxBlockedRight: maxBlockedRight = activeRight[activePos]
        activePos += 1
      if candidateX >= maxBlockedRight:
        appendOutput($candidateX & " " & $candidateY & "\n")
        placed = true
        break
    if placed: break
  if not placed:
    appendOutput("Fail!\n")

stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17

type HullLine = object
  slope: int64
  intercept: int64

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

proc lineValue(line: HullLine, position: int64): int64 =
  return line.slope * position + line.intercept

proc isObsolete(firstLine, middleLine, lastLine: HullLine): bool =
  let leftSide = (middleLine.intercept - firstLine.intercept) *
      (middleLine.slope - lastLine.slope)
  let rightSide = (lastLine.intercept - middleLine.intercept) *
      (firstLine.slope - middleLine.slope)
  return leftSide >= rightSide

proc addLine(hull: var seq[HullLine], head: var int, slope: int64, intercept: int64) =
  if hull.len > head and hull[hull.len - 1].slope == slope:
    if intercept < hull[hull.len - 1].intercept:
      hull[hull.len - 1].intercept = intercept
    return
  hull.add(HullLine(slope: slope, intercept: intercept))
  while hull.len - head >= 3 and isObsolete(hull[hull.len - 3],
      hull[hull.len - 2], hull[hull.len - 1]):
    hull[hull.len - 2] = hull[hull.len - 1]
    hull.setLen(hull.len - 1)

proc query(hull: seq[HullLine], head: var int, position: int64): int64 =
  while head + 1 < hull.len and lineValue(hull[head], position) >=
      lineValue(hull[head + 1], position):
    head += 1
  return lineValue(hull[head], position)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let outpostCount = nextInt(inputData, scanPos)
let attackCount = nextInt(inputData, scanPos)
var prefixSum = newSeq[int64](outpostCount + 1)
var prefixSquares = newSeq[int64](outpostCount + 1)
for outpostIndex in 0 .. outpostCount - 1:
  let outpostValue = int64(nextInt(inputData, scanPos))
  prefixSum[outpostIndex + 1] = prefixSum[outpostIndex] + outpostValue
  prefixSquares[outpostIndex + 1] = prefixSquares[outpostIndex] +
      outpostValue * outpostValue

var previousCosts = newSeq[int64](outpostCount + 1)
for filledCount in 1 .. outpostCount:
  let total = prefixSum[filledCount]
  previousCosts[filledCount] = (total * total - prefixSquares[filledCount]) div 2

let groupCount = attackCount + 1
if groupCount >= 2:
  for currentGroups in 2 .. groupCount:
    var currentCosts = newSeq[int64](outpostCount + 1)
    var hull = newSeq[HullLine]()
    var head = 0
    for filledCount in currentGroups .. outpostCount:
      let split = filledCount - 1
      let splitTotal = prefixSum[split]
      let slope = -2 * splitTotal
      let intercept = 2 * previousCosts[split] + splitTotal * splitTotal +
          prefixSquares[split]
      addLine(hull, head, slope, intercept)
      let position = prefixSum[filledCount]
      let bestLine = query(hull, head, position)
      let total = prefixSum[filledCount]
      currentCosts[filledCount] = (total * total - prefixSquares[filledCount] +
          bestLine) div 2
    previousCosts = currentCosts

appendOutput($previousCosts[outpostCount])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

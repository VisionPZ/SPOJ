import strutils

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

proc formatResult(value: float): string =
  let text = formatFloat(value, ffDecimal, 6)
  var lastIndex = text.len - 1
  while lastIndex >= 0 and text[lastIndex] == '0':
    lastIndex -= 1
  if lastIndex >= 0 and text[lastIndex] == '.':
    lastIndex -= 1
  return text[0 .. lastIndex]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let orcCount = nextInt(inputData, scanPos)
  var headEdges = newSeq[int](orcCount + 1)
  var toNodes = newSeq[int](2 * orcCount)
  var nextEdges = newSeq[int](2 * orcCount)
  for edgeIndex in 0 .. orcCount:
    headEdges[edgeIndex] = -1
  var edgePos = 0
  for pairIndex in 0 .. orcCount - 2:
    let firstOrc = nextInt(inputData, scanPos)
    let secondOrc = nextInt(inputData, scanPos)
    toNodes[edgePos] = secondOrc
    nextEdges[edgePos] = headEdges[firstOrc]
    headEdges[firstOrc] = edgePos
    edgePos += 1
    toNodes[edgePos] = firstOrc
    nextEdges[edgePos] = headEdges[secondOrc]
    headEdges[secondOrc] = edgePos
    edgePos += 1
  let deadCount = nextInt(inputData, scanPos)
  var isDead = newSeq[bool](orcCount + 1)
  for deadIndex in 0 .. deadCount - 1:
    let deadOrc = nextInt(inputData, scanPos)
    isDead[deadOrc] = true
  var deadAncestors = newSeq[int](orcCount + 1)
  var visitedOrcs = newSeq[bool](orcCount + 1)
  var walkNodes = newSeq[int](orcCount)
  var walkCounts = newSeq[int](orcCount)
  var walkSize = 0
  walkNodes[walkSize] = 1
  walkCounts[walkSize] = 0
  visitedOrcs[1] = true
  walkSize += 1
  while walkSize > 0:
    walkSize -= 1
    let currentOrc = walkNodes[walkSize]
    let ancestorCount = walkCounts[walkSize]
    deadAncestors[currentOrc] = ancestorCount
    var childCount = ancestorCount
    if isDead[currentOrc]:
      childCount += 1
    var edgePointer = headEdges[currentOrc]
    while edgePointer != -1:
      let childOrc = toNodes[edgePointer]
      if not visitedOrcs[childOrc]:
        visitedOrcs[childOrc] = true
        walkNodes[walkSize] = childOrc
        walkCounts[walkSize] = childCount
        walkSize += 1
      edgePointer = nextEdges[edgePointer]
  var expectedSaves: float = 0.0
  for orcLabel in 1 .. orcCount:
    let ancestorCount = deadAncestors[orcLabel]
    expectedSaves = expectedSaves + float(ancestorCount) / float(ancestorCount + 1)
  appendOutput(formatResult(expectedSaves))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

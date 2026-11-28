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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let pageCount = nextInt(inputData, scanPos)
let linkCount = nextInt(inputData, scanPos)
var forwardHead = newSeq[int](pageCount)
var reverseHead = newSeq[int](pageCount)
for pageIndex in 0 .. pageCount - 1:
  forwardHead[pageIndex] = -1
  reverseHead[pageIndex] = -1
var forwardTarget = newSeq[int](linkCount)
var forwardNext = newSeq[int](linkCount)
var reverseSource = newSeq[int](linkCount)
var reverseNext = newSeq[int](linkCount)
for linkIndex in 0 .. linkCount - 1:
  let sourcePage = nextInt(inputData, scanPos)
  let targetPage = nextInt(inputData, scanPos)
  forwardTarget[linkIndex] = targetPage
  forwardNext[linkIndex] = forwardHead[sourcePage]
  forwardHead[sourcePage] = linkIndex
  reverseSource[linkIndex] = sourcePage
  reverseNext[linkIndex] = reverseHead[targetPage]
  reverseHead[targetPage] = linkIndex

var pageVisited = newSeq[bool](pageCount)
var finishOrder = newSeq[int](pageCount)
finishOrder.setLen 0
var stackPages = newSeq[int](pageCount)
var stackEdges = newSeq[int](pageCount)
for startPage in 0 .. pageCount - 1:
  if pageVisited[startPage]:
    continue
  var stackSize = 0
  pageVisited[startPage] = true
  stackPages[0] = startPage
  stackEdges[0] = forwardHead[startPage]
  stackSize = 1
  while stackSize > 0:
    let topPosition = stackSize - 1
    let currentEdge = stackEdges[topPosition]
    if currentEdge != -1:
      stackEdges[topPosition] = forwardNext[currentEdge]
      let nextPage = forwardTarget[currentEdge]
      if not pageVisited[nextPage]:
        pageVisited[nextPage] = true
        stackPages[stackSize] = nextPage
        stackEdges[stackSize] = forwardHead[nextPage]
        stackSize += 1
    else:
      finishOrder.add stackPages[topPosition]
      stackSize -= 1

var componentId = newSeq[int](pageCount)
for pageIndex in 0 .. pageCount - 1:
  componentId[pageIndex] = -1
var componentPages = newSeq[int](pageCount)
var finishIndex = finishOrder.len - 1
while finishIndex >= 0:
  let startPage = finishOrder[finishIndex]
  finishIndex -= 1
  if componentId[startPage] != -1:
    continue
  var componentSize = 0
  componentPages[0] = startPage
  componentSize = 1
  componentId[startPage] = -2
  var queueHead = 0
  while queueHead < componentSize:
    let currentPage = componentPages[queueHead]
    queueHead += 1
    var currentEdge = reverseHead[currentPage]
    while currentEdge != -1:
      let nextPage = reverseSource[currentEdge]
      if componentId[nextPage] == -1:
        componentId[nextPage] = -2
        componentPages[componentSize] = nextPage
        componentSize += 1
      currentEdge = reverseNext[currentEdge]
  var smallestPage = startPage
  for memberIndex in 0 .. componentSize - 1:
    if componentPages[memberIndex] < smallestPage:
      smallestPage = componentPages[memberIndex]
  for memberIndex in 0 .. componentSize - 1:
    componentId[componentPages[memberIndex]] = smallestPage

for pageIndex in 0 .. pageCount - 1:
  appendOutput($componentId[pageIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

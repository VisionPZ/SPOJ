const flushBlockBytes = 1 shl 17
const emptyEdge = 0

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

proc answerText(isStrong: bool): string =
  if isStrong:
    return "Yes"
  return "No"

let caseCount = nextInt(inputData, scanPos)
for caseNumber in 0 .. caseCount - 1:
  let fieldWidth = nextInt(inputData, scanPos)
  let fieldHeight = nextInt(inputData, scanPos)
  let passCount = nextInt(inputData, scanPos)
  let rowLength = fieldHeight + 1
  let siteCount = (fieldWidth + 1) * rowLength
  let goalSite = fieldWidth * rowLength + fieldHeight div 2
  var reverseHead = newSeq[int](siteCount)
  var edgeFrom = newSeq[int](passCount + 1)
  var edgeNext = newSeq[int](passCount + 1)
  var usedSite = newSeq[bool](siteCount)
  var isStrong = true
  var edgeIndex = 0
  for passNumber in 0 .. passCount - 1:
    let startX = nextInt(inputData, scanPos)
    let startY = nextInt(inputData, scanPos)
    let endX = nextInt(inputData, scanPos)
    let endY = nextInt(inputData, scanPos)
    if endX < startX:
      isStrong = false
    let startSite = startX * rowLength + startY
    let endSite = endX * rowLength + endY
    usedSite[startSite] = true
    usedSite[endSite] = true
    edgeIndex += 1
    edgeFrom[edgeIndex] = startSite
    edgeNext[edgeIndex] = reverseHead[endSite]
    reverseHead[endSite] = edgeIndex
  var reachable = newSeq[bool](siteCount)
  var queue = newSeq[int](siteCount)
  var queueHead = 0
  var queueTail = 0
  reachable[goalSite] = true
  queue[queueTail] = goalSite
  queueTail += 1
  while queueHead < queueTail:
    let currentSite = queue[queueHead]
    queueHead += 1
    var edgeCursor = reverseHead[currentSite]
    while edgeCursor != emptyEdge:
      let previousSite = edgeFrom[edgeCursor]
      if not reachable[previousSite]:
        reachable[previousSite] = true
        queue[queueTail] = previousSite
        queueTail += 1
      edgeCursor = edgeNext[edgeCursor]
  if isStrong:
    for siteIndex in 0 .. siteCount - 1:
      if usedSite[siteIndex] and not reachable[siteIndex]:
        isStrong = false
        break
  appendOutput(answerText(isStrong))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

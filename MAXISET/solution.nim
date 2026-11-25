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

proc lowestBitIndex(maskValue: int): int =
  var bitIndex = 0
  while (maskValue and (1 shl bitIndex)) == 0:
    bitIndex += 1
  return bitIndex

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let vertexCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  var weights = newSeq[int](vertexCount)
  for vertexIndex in 0 .. vertexCount - 1:
    weights[vertexIndex] = nextInt(inputData, scanPos)
  let leftCount = vertexCount div 2
  let rightCount = vertexCount - leftCount
  var leftNeighbors = newSeq[int](leftCount)
  var rightNeighbors = newSeq[int](rightCount)
  var leftCross = newSeq[int](leftCount)
  for edgeIndex in 0 .. edgeCount - 1:
    let firstVertex = nextInt(inputData, scanPos)
    let secondVertex = nextInt(inputData, scanPos)
    if firstVertex < leftCount and secondVertex < leftCount:
      leftNeighbors[firstVertex] = leftNeighbors[firstVertex] or (1 shl secondVertex)
      leftNeighbors[secondVertex] = leftNeighbors[secondVertex] or (1 shl firstVertex)
    elif firstVertex >= leftCount and secondVertex >= leftCount:
      let rightFirst = firstVertex - leftCount
      let rightSecond = secondVertex - leftCount
      rightNeighbors[rightFirst] = rightNeighbors[rightFirst] or (1 shl rightSecond)
      rightNeighbors[rightSecond] = rightNeighbors[rightSecond] or (1 shl rightFirst)
    else:
      if firstVertex >= leftCount:
        leftCross[secondVertex] = leftCross[secondVertex] or (1 shl (firstVertex - leftCount))
      else:
        leftCross[firstVertex] = leftCross[firstVertex] or (1 shl (secondVertex - leftCount))
  let leftMasks = 1 shl leftCount
  let rightMasks = 1 shl rightCount
  var leftIndependent = newSeq[bool](leftMasks)
  var leftWeight = newSeq[int](leftMasks)
  var leftForbidden = newSeq[int](leftMasks)
  leftIndependent[0] = true
  for maskValue in 1 .. leftMasks - 1:
    let lowestBit = maskValue and -maskValue
    let vertexIndex = lowestBitIndex(lowestBit)
    let remaining = maskValue xor lowestBit
    leftIndependent[maskValue] = leftIndependent[remaining] and
                                 ((leftNeighbors[vertexIndex] and remaining) == 0)
    leftWeight[maskValue] = leftWeight[remaining] + weights[vertexIndex]
    leftForbidden[maskValue] = leftForbidden[remaining] or leftCross[vertexIndex]
  var rightBest = newSeq[int](rightMasks)
  for maskValue in 1 .. rightMasks - 1:
    let lowestBit = maskValue and -maskValue
    let vertexIndex = lowestBitIndex(lowestBit)
    let remaining = maskValue xor lowestBit
    let withoutVertex = remaining and not rightNeighbors[vertexIndex]
    let takeValue = weights[leftCount + vertexIndex] + rightBest[withoutVertex]
    if takeValue > rightBest[maskValue]:
      rightBest[maskValue] = takeValue
    if rightBest[remaining] > rightBest[maskValue]:
      rightBest[maskValue] = rightBest[remaining]
  let queryCount = nextInt(inputData, scanPos)
  if caseIndex > 0:
    appendOutput("\n")
  for queryIndex in 0 .. queryCount - 1:
    let memberCount = nextInt(inputData, scanPos)
    var leftMask = 0
    var rightMask = 0
    for memberIndex in 0 .. memberCount - 1:
      let vertexIndex = nextInt(inputData, scanPos)
      if vertexIndex < leftCount:
        leftMask = leftMask or (1 shl vertexIndex)
      else:
        rightMask = rightMask or (1 shl (vertexIndex - leftCount))
    var bestSet = 0
    var submask = leftMask
    while true:
      if leftIndependent[submask]:
        let allowedRight = rightMask and not leftForbidden[submask]
        let candidate = leftWeight[submask] + rightBest[allowedRight]
        if candidate > bestSet:
          bestSet = candidate
      if submask == 0:
        break
      submask = (submask - 1) and leftMask
    appendOutput($bestSet & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0

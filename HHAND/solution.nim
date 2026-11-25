const flushBlockBytes = 1 shl 17
const infiniteCost = int64(1) shl 60

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

proc solveCase(townCount: int, reachLimit: int, edgeCount: int, scanPosition: var int): int64 =
  var edgeHead = newSeq[int](townCount)
  for headIndex in 0 .. townCount - 1:
    edgeHead[headIndex] = -1
  var edgeTo = newSeq[int](2 * edgeCount)
  var edgeNext = newSeq[int](2 * edgeCount)
  for edgeIndex in 0 .. edgeCount - 1:
    let firstTown = nextInt(inputData, scanPosition)
    let secondTown = nextInt(inputData, scanPosition)
    let forwardIndex = 2 * edgeIndex
    let backwardIndex = 2 * edgeIndex + 1
    edgeTo[forwardIndex] = secondTown
    edgeTo[backwardIndex] = firstTown
    edgeNext[forwardIndex] = edgeHead[firstTown]
    edgeNext[backwardIndex] = edgeHead[secondTown]
    edgeHead[firstTown] = forwardIndex
    edgeHead[secondTown] = backwardIndex

  var parentTown = newSeq[int](townCount)
  for townIndex in 0 .. townCount - 1:
    parentTown[townIndex] = -1
  parentTown[0] = -2
  var queue = newSeq[int](townCount)
  var queueHead = 0
  var queueTail = 0
  queue[queueTail] = 0
  queueTail += 1
  while queueHead < queueTail:
    let currentTown = queue[queueHead]
    queueHead += 1
    var edgeIndex = edgeHead[currentTown]
    while edgeIndex >= 0:
      let neighborTown = edgeTo[edgeIndex]
      if parentTown[neighborTown] == -1:
        parentTown[neighborTown] = currentTown
        queue[queueTail] = neighborTown
        queueTail += 1
      edgeIndex = edgeNext[edgeIndex]

  var subtreeSize = newSeq[int](townCount)
  var distanceSum = newSeq[int64](townCount)
  for townIndex in 0 .. townCount - 1:
    subtreeSize[townIndex] = 1
  var orderIndex = townCount - 1
  while orderIndex >= 0:
    let currentTown = queue[orderIndex]
    var edgeIndex = edgeHead[currentTown]
    while edgeIndex >= 0:
      let neighborTown = edgeTo[edgeIndex]
      if parentTown[neighborTown] == currentTown:
        subtreeSize[currentTown] = subtreeSize[currentTown] + subtreeSize[neighborTown]
        distanceSum[currentTown] = distanceSum[currentTown] + distanceSum[neighborTown] + int64(subtreeSize[neighborTown])
      edgeIndex = edgeNext[edgeIndex]
    orderIndex -= 1

  var totalDistance = newSeq[int64](townCount)
  totalDistance[0] = distanceSum[0]
  for forwardIndex in 0 .. townCount - 1:
    let currentTown = queue[forwardIndex]
    var edgeIndex = edgeHead[currentTown]
    while edgeIndex >= 0:
      let neighborTown = edgeTo[edgeIndex]
      if parentTown[neighborTown] == currentTown:
        totalDistance[neighborTown] = totalDistance[currentTown] + int64(townCount) - 2 * int64(subtreeSize[neighborTown])
      edgeIndex = edgeNext[edgeIndex]

  var distanceToParent = newSeq[int64](townCount)
  for townIndex in 1 .. townCount - 1:
    distanceToParent[townIndex] = totalDistance[townIndex] - distanceSum[townIndex]

  let chainWidth = reachLimit + 1
  var downChain = newSeq[int64](townCount * chainWidth)
  for chainIndex in 0 .. downChain.len - 1:
    downChain[chainIndex] = infiniteCost
  for townIndex in 0 .. townCount - 1:
    downChain[townIndex * chainWidth] = 0
    downChain[townIndex * chainWidth + 1] = totalDistance[townIndex] - distanceToParent[townIndex]

  orderIndex = townCount - 1
  while orderIndex >= 0:
    let currentTown = queue[orderIndex]
    for chainLength in 2 .. reachLimit:
      var bestBranch = infiniteCost
      var edgeIndex = edgeHead[currentTown]
      while edgeIndex >= 0:
        let neighborTown = edgeTo[edgeIndex]
        if parentTown[neighborTown] == currentTown:
          let candidate = downChain[neighborTown * chainWidth + chainLength - 1] - (distanceSum[neighborTown] + int64(subtreeSize[neighborTown]))
          if candidate < bestBranch:
            bestBranch = candidate
        edgeIndex = edgeNext[edgeIndex]
      if bestBranch < infiniteCost div 2:
        downChain[currentTown * chainWidth + chainLength] = totalDistance[currentTown] - distanceToParent[currentTown] + bestBranch
    orderIndex -= 1

  var bestCost = infiniteCost
  for apexTown in 0 .. townCount - 1:
    var bestBranch = newSeq[int64](chainWidth)
    var bestChild = newSeq[int](chainWidth)
    var secondBranch = newSeq[int64](chainWidth)
    var secondChild = newSeq[int](chainWidth)
    for chainLength in 0 .. reachLimit:
      bestBranch[chainLength] = infiniteCost
      secondBranch[chainLength] = infiniteCost
      bestChild[chainLength] = -1
      secondChild[chainLength] = -1
    bestBranch[0] = 0
    secondBranch[0] = 0
    var edgeIndex = edgeHead[apexTown]
    while edgeIndex >= 0:
      let neighborTown = edgeTo[edgeIndex]
      if parentTown[neighborTown] == apexTown:
        let childDistance = distanceSum[neighborTown] + int64(subtreeSize[neighborTown])
        for chainLength in 1 .. reachLimit:
          let candidate = downChain[neighborTown * chainWidth + chainLength] - childDistance
          if candidate < bestBranch[chainLength]:
            secondBranch[chainLength] = bestBranch[chainLength]
            secondChild[chainLength] = bestChild[chainLength]
            bestBranch[chainLength] = candidate
            bestChild[chainLength] = neighborTown
          elif candidate < secondBranch[chainLength]:
            secondBranch[chainLength] = candidate
            secondChild[chainLength] = neighborTown
      edgeIndex = edgeNext[edgeIndex]

    var totalLength = reachLimit
    while totalLength >= 0:
      var combined = infiniteCost
      for leftLength in 0 .. totalLength:
        let rightLength = totalLength - leftLength
        var branchTotal: int64
        if bestChild[leftLength] != bestChild[rightLength]:
          branchTotal = bestBranch[leftLength] + bestBranch[rightLength]
        else:
          let firstChoice = bestBranch[leftLength] + secondBranch[rightLength]
          let secondChoice = secondBranch[leftLength] + bestBranch[rightLength]
          branchTotal = firstChoice
          if secondChoice < branchTotal:
            branchTotal = secondChoice
        if branchTotal < combined:
          combined = branchTotal
      if combined < infiniteCost div 2:
        let candidateCost = totalDistance[apexTown] + combined
        if candidateCost < bestCost:
          bestCost = candidateCost
        break
      totalLength -= 1

  return bestCost

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let townCount = nextInt(inputData, scanPos)
  let reachLimit = nextInt(inputData, scanPos)
  appendOutput($solveCase(townCount, reachLimit, townCount - 1, scanPos))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

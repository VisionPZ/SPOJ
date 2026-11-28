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

type EvilMember = tuple[firstScore, secondScore, thirdScore: int]

var compressedY = newSeq[int](0)
var bestZ = newSeq[int](0)
var previousNode = newSeq[int](0)
var followingNode = newSeq[int](0)
var nodeActive = newSeq[bool](0)
var fenwickTree = newSeq[int](0)
var highestPower = 1
var staircaseTotal: int64 = 0

proc fenwickAdd(nodeIndex, delta: int) =
  var position = nodeIndex + 1
  while position <= fenwickTree.len - 1:
    fenwickTree[position] += delta
    position += position and (-position)

proc fenwickPrefix(nodeIndex: int): int =
  var position = nodeIndex + 1
  var totalSum = 0
  while position > 0:
    totalSum += fenwickTree[position]
    position -= position and (-position)
  return totalSum

proc fenwickFind(kthValue: int): int =
  var remaining = kthValue
  var position = 0
  var stepSize = highestPower
  while stepSize > 0:
    let candidate = position + stepSize
    if candidate <= fenwickTree.len - 1 and fenwickTree[candidate] < remaining:
      position = candidate
      remaining -= fenwickTree[candidate]
    stepSize = stepSize div 2
  return position

proc firstActiveAtOrAfter(nodeIndex: int): int =
  let countBefore = fenwickPrefix(nodeIndex - 1)
  if fenwickPrefix(compressedY.len - 1) <= countBefore:
    return -1
  return fenwickFind(countBefore + 1)

proc lastActiveBefore(nodeIndex: int): int =
  let countBefore = fenwickPrefix(nodeIndex - 1)
  if countBefore == 0:
    return -1
  return fenwickFind(countBefore)

proc boundaryAfter(nodeIndex: int, cellCount: int): int =
  if nodeIndex == -1 or followingNode[nodeIndex] == -1:
    return cellCount + 1
  return compressedY[followingNode[nodeIndex]]

proc removeNode(nodeIndex: int, cellCount: int) =
  let predecessor = previousNode[nodeIndex]
  let successor = followingNode[nodeIndex]
  let currentY = compressedY[nodeIndex]
  let boundaryY = boundaryAfter(nodeIndex, cellCount)
  staircaseTotal -= int64(boundaryY - currentY) * int64(bestZ[nodeIndex] - 1)
  if predecessor == -1:
    staircaseTotal += int64(boundaryY - currentY) * int64(cellCount)
  else:
    staircaseTotal += int64(boundaryY - currentY) * int64(bestZ[predecessor] - 1)
  if predecessor == -1:
    if successor != -1:
      previousNode[successor] = -1
  else:
    if successor == -1:
      followingNode[predecessor] = -1
    else:
      followingNode[predecessor] = successor
      previousNode[successor] = predecessor
  nodeActive[nodeIndex] = false
  fenwickAdd(nodeIndex, -1)

proc insertNode(nodeIndex, zValue: int, cellCount: int) =
  let predecessor = lastActiveBefore(nodeIndex)
  let successor = firstActiveAtOrAfter(nodeIndex)
  let currentY = compressedY[nodeIndex]
  var boundaryY = cellCount + 1
  if successor != -1:
    boundaryY = compressedY[successor]
  if predecessor == -1:
    staircaseTotal += int64(boundaryY - currentY) * int64(zValue - 1 - cellCount)
  else:
    staircaseTotal += int64(boundaryY - currentY) * int64(zValue - bestZ[predecessor])
  previousNode[nodeIndex] = predecessor
  followingNode[nodeIndex] = successor
  if predecessor != -1:
    followingNode[predecessor] = nodeIndex
  if successor != -1:
    previousNode[successor] = nodeIndex
  bestZ[nodeIndex] = zValue
  nodeActive[nodeIndex] = true
  fenwickAdd(nodeIndex, 1)

proc insertBreakpoint(nodeIndex, zValue: int, cellCount: int) =
  if nodeActive[nodeIndex]:
    if bestZ[nodeIndex] <= zValue:
      return
    removeNode(nodeIndex, cellCount)
  let predecessor = lastActiveBefore(nodeIndex)
  if predecessor != -1 and bestZ[predecessor] <= zValue:
    return
  var currentNode = firstActiveAtOrAfter(nodeIndex)
  while currentNode != -1 and bestZ[currentNode] >= zValue:
    let following = followingNode[currentNode]
    removeNode(currentNode, cellCount)
    currentNode = following
  insertNode(nodeIndex, zValue, cellCount)

while true:
  let memberCount = nextInt(inputData, scanPos)
  let scoreLimit = nextInt(inputData, scanPos)
  if memberCount == 0 and scoreLimit == 0:
    break
  var members = newSeq[EvilMember](memberCount)
  for memberIndex in 0 .. memberCount - 1:
    members[memberIndex].firstScore = nextInt(inputData, scanPos)
    let secondScore = nextInt(inputData, scanPos)
    let thirdScore = nextInt(inputData, scanPos)
    members[memberIndex].secondScore = scoreLimit + 1 - secondScore
    members[memberIndex].thirdScore = scoreLimit + 1 - thirdScore

  var sortIndex = 1
  while sortIndex < memberCount:
    let currentMember = members[sortIndex]
    var previousIndex = sortIndex - 1
    while previousIndex >= 0 and members[previousIndex].firstScore < currentMember.firstScore:
      members[previousIndex + 1] = members[previousIndex]
      previousIndex -= 1
    members[previousIndex + 1] = currentMember
    sortIndex += 1

  compressedY = @[]
  for member in members:
    compressedY.add(member.secondScore)
  var sortEnd = 1
  while sortEnd < compressedY.len:
    let currentY = compressedY[sortEnd]
    var previousIndex = sortEnd - 1
    while previousIndex >= 0 and compressedY[previousIndex] > currentY:
      compressedY[previousIndex + 1] = compressedY[previousIndex]
      previousIndex -= 1
    compressedY[previousIndex + 1] = currentY
    sortEnd += 1
  var uniqueCount = 0
  sortIndex = 0
  while sortIndex < compressedY.len:
    if sortIndex == 0 or compressedY[sortIndex] != compressedY[sortIndex - 1]:
      compressedY[uniqueCount] = compressedY[sortIndex]
      uniqueCount += 1
    sortIndex += 1
  compressedY.setLen(uniqueCount)

  bestZ = newSeq[int](uniqueCount)
  previousNode = newSeq[int](uniqueCount)
  followingNode = newSeq[int](uniqueCount)
  nodeActive = newSeq[bool](uniqueCount)
  fenwickTree = newSeq[int](uniqueCount + 1)
  for nodeIndex in 0 .. uniqueCount - 1:
    previousNode[nodeIndex] = -1
    followingNode[nodeIndex] = -1
  highestPower = 1
  while highestPower shl 1 <= uniqueCount:
    highestPower = highestPower shl 1
  staircaseTotal = int64(scoreLimit) * int64(scoreLimit)

  var heroTotal: int64 = 0
  var previousScore = scoreLimit + 1
  var memberIndex = 0
  while memberIndex < memberCount:
    let currentScore = members[memberIndex].firstScore
    heroTotal += int64(previousScore - currentScore - 1) * staircaseTotal
    while memberIndex < memberCount and members[memberIndex].firstScore == currentScore:
      var lowIndex = 0
      var highIndex = uniqueCount - 1
      while lowIndex < highIndex:
        let middleIndex = (lowIndex + highIndex) div 2
        if compressedY[middleIndex] < members[memberIndex].secondScore:
          lowIndex = middleIndex + 1
        else:
          highIndex = middleIndex
      insertBreakpoint(lowIndex, members[memberIndex].thirdScore, scoreLimit)
      memberIndex += 1
    heroTotal += staircaseTotal
    previousScore = currentScore
  heroTotal += int64(previousScore - 1) * staircaseTotal
  appendOutput($heroTotal)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

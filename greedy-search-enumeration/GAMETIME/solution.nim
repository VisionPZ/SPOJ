const flushBlockBytes = 1 shl 17
const noParent = -1

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let castleCount = nextInt(inputData, scanPos)
  if castleCount == 0:
    break
  var conquerTimes = newSeq[int64](castleCount)
  var parentNodes = newSeq[int](castleCount)
  for castleIndex in 0 .. castleCount - 1:
    conquerTimes[castleIndex] = int64(nextInt(inputData, scanPos))
  for castleIndex in 0 .. castleCount - 1:
    parentNodes[castleIndex] = nextInt(inputData, scanPos)
  var childHeads = newSeq[int](castleCount)
  var nextSiblings = newSeq[int](castleCount)
  for castleIndex in 0 .. castleCount - 1:
    childHeads[castleIndex] = noParent
    nextSiblings[castleIndex] = noParent
  for castleIndex in 0 .. castleCount - 1:
    let parentNode = parentNodes[castleIndex]
    if parentNode >= 0:
      nextSiblings[castleIndex] = childHeads[parentNode]
      childHeads[parentNode] = castleIndex
  var traversalOrder = newSeq[int](castleCount)
  var traversalStack = newSeq[int](castleCount)
  var orderLength = 0
  var stackLength = 0
  for castleIndex in 0 .. castleCount - 1:
    if parentNodes[castleIndex] == noParent:
      traversalStack[stackLength] = castleIndex
      stackLength += 1
  while stackLength > 0:
    stackLength -= 1
    let currentNode = traversalStack[stackLength]
    traversalOrder[orderLength] = currentNode
    orderLength += 1
    var childNode = childHeads[currentNode]
    while childNode != noParent:
      traversalStack[stackLength] = childNode
      stackLength += 1
      childNode = nextSiblings[childNode]
  var subtreeTotals = newSeq[int64](castleCount)
  var unbeatenScores = newSeq[int64](castleCount)
  var lastScores = newSeq[int64](castleCount)
  var reverseIndex = orderLength - 1
  while reverseIndex >= 0:
    let currentNode = traversalOrder[reverseIndex]
    var baseScore: int64 = 0
    var subtreeTotal: int64 = conquerTimes[currentNode]
    var bestFullGain: int64 = 0
    var secondFullGain: int64 = 0
    var bestFullChild = noParent
    var childNode = childHeads[currentNode]
    while childNode != noParent:
      baseScore = baseScore + unbeatenScores[childNode]
      subtreeTotal = subtreeTotal + subtreeTotals[childNode]
      let fullGain = subtreeTotals[childNode] - unbeatenScores[childNode]
      if fullGain > bestFullGain:
        secondFullGain = bestFullGain
        bestFullGain = fullGain
        bestFullChild = childNode
      elif fullGain > secondFullGain:
        secondFullGain = fullGain
      childNode = nextSiblings[childNode]
    unbeatenScores[currentNode] = baseScore + bestFullGain
    var bestPair: int64 = 0
    childNode = childHeads[currentNode]
    while childNode != noParent:
      let fullGainExcluding = if childNode == bestFullChild: secondFullGain else: bestFullGain
      let triggerGain = lastScores[childNode] - unbeatenScores[childNode]
      let pairScore = fullGainExcluding + triggerGain
      if pairScore > bestPair:
        bestPair = pairScore
      childNode = nextSiblings[childNode]
    if bestPair > bestFullGain:
      lastScores[currentNode] = conquerTimes[currentNode] + baseScore + bestPair
    else:
      lastScores[currentNode] = conquerTimes[currentNode] + baseScore + bestFullGain
    subtreeTotals[currentNode] = subtreeTotal
    reverseIndex -= 1
  let kingCastle = castleCount - 1
  var bestTime: int64 = 0
  for castleIndex in 0 .. castleCount - 1:
    if parentNodes[castleIndex] != noParent:
      continue
    if castleIndex == kingCastle:
      bestTime = bestTime + lastScores[castleIndex]
    else:
      bestTime = bestTime + subtreeTotals[castleIndex]
  appendOutput($bestTime)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

import tables

const flushBlockBytes = 1 shl 17
const infiniteCost = 1000000000

var heapKeys = newSeq[int64]()
var heapCosts = newSeq[int]()

proc heapPush(keyValue: int64, costValue: int) =
  heapKeys.add keyValue
  heapCosts.add costValue
  var childIndex = heapKeys.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heapCosts[parentIndex] <= heapCosts[childIndex]:
      break
    swap heapCosts[parentIndex], heapCosts[childIndex]
    swap heapKeys[parentIndex], heapKeys[childIndex]
    childIndex = parentIndex

proc heapPop(): tuple[keyValue: int64, costValue: int] =
  let resultKey = heapKeys[0]
  let resultCost = heapCosts[0]
  let lastIndex = heapKeys.len - 1
  heapKeys[0] = heapKeys[lastIndex]
  heapCosts[0] = heapCosts[lastIndex]
  heapKeys.setLen lastIndex
  heapCosts.setLen lastIndex
  var parentIndex = 0
  while true:
    let leftIndex = parentIndex * 2 + 1
    if leftIndex >= heapKeys.len:
      break
    let rightIndex = leftIndex + 1
    var smallestIndex = leftIndex
    if rightIndex < heapKeys.len and heapCosts[rightIndex] < heapCosts[leftIndex]:
      smallestIndex = rightIndex
    if heapCosts[parentIndex] <= heapCosts[smallestIndex]:
      break
    swap heapCosts[parentIndex], heapCosts[smallestIndex]
    swap heapKeys[parentIndex], heapKeys[smallestIndex]
    parentIndex = smallestIndex
  return (resultKey, resultCost)

proc digitCount(value: int): int =
  var remaining = value
  result = 0
  while remaining > 0:
    result += 1
    remaining = remaining div 10

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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let channelCount = nextInt(inputData, scanPos)
  let bannedCount = nextInt(inputData, scanPos)
  var isAllowed = newSeq[bool](channelCount + 1)
  for channelIndex in 1 .. channelCount:
    isAllowed[channelIndex] = true
  for bannedIndex in 0 .. bannedCount - 1:
    isAllowed[nextInt(inputData, scanPos)] = false
  let targetCount = nextInt(inputData, scanPos)
  var targets = newSeq[int](targetCount)
  for targetIndex in 0 .. targetCount - 1:
    targets[targetIndex] = nextInt(inputData, scanPos)
  var nextUp = newSeq[int](channelCount + 1)
  var nextDown = newSeq[int](channelCount + 1)
  var firstAllowed = 1
  while firstAllowed <= channelCount and not isAllowed[firstAllowed]:
    firstAllowed += 1
  var lastAllowed = channelCount
  while lastAllowed >= 1 and not isAllowed[lastAllowed]:
    lastAllowed -= 1
  for channelIndex in 1 .. channelCount:
    if not isAllowed[channelIndex]:
      continue
    var upward = channelIndex + 1
    while upward <= channelCount and not isAllowed[upward]:
      upward += 1
    if upward > channelCount:
      upward = firstAllowed
    nextUp[channelIndex] = upward
    var downward = channelIndex - 1
    while downward >= 1 and not isAllowed[downward]:
      downward -= 1
    if downward < 1:
      downward = lastAllowed
    nextDown[channelIndex] = downward
  var digitCandidates = newSeq[int]()
  if channelCount <= 12:
    for channelIndex in 1 .. channelCount:
      if isAllowed[channelIndex]:
        digitCandidates.add channelIndex
  else:
    var markedChannel = newSeq[bool](channelCount + 1)
    for channelIndex in 1 .. min(9, channelCount):
      markedChannel[channelIndex] = true
    for targetIndex in 0 .. targetCount - 1:
      let targetChannel = targets[targetIndex]
      markedChannel[targetChannel] = true
      var prefixChannel = targetChannel div 10
      while prefixChannel > 0:
        markedChannel[prefixChannel] = true
        prefixChannel = prefixChannel div 10
      if targetChannel > 1:
        markedChannel[targetChannel - 1] = true
      if targetChannel < channelCount:
        markedChannel[targetChannel + 1] = true
    for channelIndex in 1 .. channelCount:
      if markedChannel[channelIndex] and isAllowed[channelIndex]:
        digitCandidates.add channelIndex
  let stateWidth = channelCount + 1
  let progressWidth = targetCount + 1
  var distances = initTable[int64, int]()
  heapKeys.setLen 0
  heapCosts.setLen 0
  let firstChannel = targets[0]
  let initialKey = int64(firstChannel) * int64(progressWidth) + 1
  let initialCost = digitCount(firstChannel)
  distances[initialKey] = initialCost
  heapPush(initialKey, initialCost)
  var bestCost = infiniteCost
  var expandedStates = 0
  while heapKeys.len > 0:
    expandedStates += 1
    if expandedStates > 300000:
      break
    let topEntry = heapPop()
    let currentKey = topEntry.keyValue
    let currentCost = topEntry.costValue
    if currentCost >= bestCost:
      break
    if distances.getOrDefault(currentKey, infiniteCost) != currentCost:
      continue
    let progressIndex = int(currentKey mod int64(progressWidth))
    if progressIndex == targetCount:
      bestCost = currentCost
      break
    let remainingKey = currentKey div int64(progressWidth)
    let currentChannel = int(remainingKey mod int64(stateWidth))
    let priorChannel = int(remainingKey div int64(stateWidth))
    let wantedChannel = targets[progressIndex]
    let currentDigits = digitCount(currentChannel)
    var prefixDivisor = 1
    for digitPosition in 0 .. currentDigits - 1:
      prefixDivisor = prefixDivisor * 10
    var destinations = newSeq[int]()
    var stepCosts = newSeq[int]()
    destinations.add nextUp[currentChannel]
    stepCosts.add 1
    destinations.add nextDown[currentChannel]
    stepCosts.add 1
    if priorChannel > 0:
      destinations.add priorChannel
      stepCosts.add 1
    for channelIndex in digitCandidates:
      if channelIndex == currentChannel:
        continue
      let candidateDigits = digitCount(channelIndex)
      var moveCost = candidateDigits
      if channelIndex div prefixDivisor == currentChannel:
        moveCost = candidateDigits - currentDigits
      destinations.add channelIndex
      stepCosts.add moveCost
    for moveIndex in 0 .. destinations.len - 1:
      let candidateChannel = destinations[moveIndex]
      let moveCost = stepCosts[moveIndex]
      if currentCost + moveCost >= bestCost:
        continue
      var advanced = progressIndex
      if candidateChannel == wantedChannel:
        advanced = progressIndex + 1
      if advanced == targetCount:
        if currentCost + moveCost < bestCost:
          bestCost = currentCost + moveCost
        continue
      let newKey = (int64(currentChannel) * int64(stateWidth) +
                    int64(candidateChannel)) * int64(progressWidth) +
                   int64(advanced)
      let oldCost = distances.getOrDefault(newKey, infiniteCost)
      if currentCost + moveCost < oldCost:
        distances[newKey] = currentCost + moveCost
        heapPush(newKey, currentCost + moveCost)
  if bestCost == infiniteCost:
    bestCost = digitCount(targets[0])
    for targetIndex in 1 .. targetCount - 1:
      let priorTarget = targets[targetIndex - 1]
      let nextTarget = targets[targetIndex]
      var nearbyCost = digitCount(nextTarget)
      var walkingCost: int
      if nextTarget > priorTarget:
        walkingCost = nextTarget - priorTarget
      else:
        walkingCost = channelCount - priorTarget + nextTarget
      if walkingCost < nearbyCost:
        nearbyCost = walkingCost
      bestCost = bestCost + nearbyCost
  appendOutput("Case #" & $(caseIndex + 1) & ": " & $bestCost)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

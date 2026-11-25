const flushBlockBytes = 1 shl 17
const infiniteCost = 1000000000

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

let testCaseCount = nextInt(inputData, scanPos)
for testCaseIndex in 0 .. testCaseCount - 1:
  let personCount = nextInt(inputData, scanPos)
  var accusedBy = newSeq[int](personCount)
  var incomingHead = newSeq[int](personCount)
  var incomingNext = newSeq[int](personCount)
  var incomingPerson = newSeq[int](personCount)
  var incomingCount = newSeq[int](personCount)
  var edgeIndex = 0
  for personIndex in 0 .. personCount - 1:
    incomingHead[personIndex] = -1
  for personIndex in 0 .. personCount - 1:
    let accusedPerson = nextInt(inputData, scanPos) - 1
    accusedBy[personIndex] = accusedPerson
    incomingCount[accusedPerson] += 1
    incomingPerson[edgeIndex] = personIndex
    incomingNext[edgeIndex] = incomingHead[accusedPerson]
    incomingHead[accusedPerson] = edgeIndex
    edgeIndex += 1
  var peelQueue = newSeq[int](personCount)
  var peeled = newSeq[bool](personCount)
  var peelOrder = newSeq[int](personCount)
  var queueFront = 0
  var queueBack = 0
  var peeledCount = 0
  for personIndex in 0 .. personCount - 1:
    if incomingCount[personIndex] == 0:
      peelQueue[queueBack] = personIndex
      queueBack += 1
  while queueFront < queueBack:
    let currentPerson = peelQueue[queueFront]
    queueFront += 1
    peelOrder[peeledCount] = currentPerson
    peeledCount += 1
    peeled[currentPerson] = true
    let accusedPerson = accusedBy[currentPerson]
    incomingCount[accusedPerson] -= 1
    if incomingCount[accusedPerson] == 0:
      peelQueue[queueBack] = accusedPerson
      queueBack += 1
  var coverWhenFree = newSeq[int](personCount)
  var coverWhenGuilty = newSeq[int](personCount)
  for orderIndex in 0 .. peeledCount - 1:
    let currentPerson = peelOrder[orderIndex]
    var freeCost = 0
    var guiltyCost = 1
    var edgeCursor = incomingHead[currentPerson]
    while edgeCursor != -1:
      let childPerson = incomingPerson[edgeCursor]
      freeCost += coverWhenGuilty[childPerson]
      guiltyCost += min(coverWhenFree[childPerson], coverWhenGuilty[childPerson])
      edgeCursor = incomingNext[edgeCursor]
    coverWhenFree[currentPerson] = freeCost
    coverWhenGuilty[currentPerson] = guiltyCost
  var cycleFreeCost = newSeq[int](personCount)
  var cycleGuiltyCost = newSeq[int](personCount)
  var onCycle = newSeq[bool](personCount)
  for personIndex in 0 .. personCount - 1:
    if not peeled[personIndex]:
      var freeCost = 0
      var guiltyCost = 1
      var edgeCursor = incomingHead[personIndex]
      while edgeCursor != -1:
        let childPerson = incomingPerson[edgeCursor]
        if peeled[childPerson]:
          freeCost += coverWhenGuilty[childPerson]
          guiltyCost += min(coverWhenFree[childPerson], coverWhenGuilty[childPerson])
        edgeCursor = incomingNext[edgeCursor]
      cycleFreeCost[personIndex] = freeCost
      cycleGuiltyCost[personIndex] = guiltyCost
      onCycle[personIndex] = true
  var totalGuilty = 0
  for startPerson in 0 .. personCount - 1:
    if not onCycle[startPerson]:
      continue
    var cyclePeople: seq[int] = @[]
    var currentPerson = startPerson
    while true:
      cyclePeople.add currentPerson
      onCycle[currentPerson] = false
      currentPerson = accusedBy[currentPerson]
      if currentPerson == startPerson:
        break
    var bestCycleCost = infiniteCost
    for firstState in 0 .. 1:
      var previousFree = infiniteCost
      var previousGuilty = infiniteCost
      let firstPerson = cyclePeople[0]
      if firstState == 0:
        previousFree = cycleFreeCost[firstPerson]
      else:
        previousGuilty = cycleGuiltyCost[firstPerson]
      for cycleIndex in 1 .. cyclePeople.len - 1:
        let currentCyclePerson = cyclePeople[cycleIndex]
        let nextFree = cycleFreeCost[currentCyclePerson] + previousGuilty
        let nextGuilty = cycleGuiltyCost[currentCyclePerson] + min(previousFree, previousGuilty)
        previousFree = nextFree
        previousGuilty = nextGuilty
      if firstState == 0:
        bestCycleCost = min(bestCycleCost, previousGuilty)
      else:
        bestCycleCost = min(bestCycleCost, min(previousFree, previousGuilty))
    totalGuilty += bestCycleCost
  appendOutput($totalGuilty)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

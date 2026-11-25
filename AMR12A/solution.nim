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

var travelTimes: seq[int] = @[]
var holeCount = 0
var diggingTime = 0
var slotOwner: seq[int] = @[]
var visitedSlots: seq[bool] = @[]

proc canUseSlot(hobbitIndex: int, slotIndex: int, deadline: int): bool =
  if slotIndex < 0 or slotIndex >= 2 * holeCount:
    return false
  let holeIndex = slotIndex div 2
  let travelTime = travelTimes[hobbitIndex * holeCount + holeIndex]
  if slotIndex mod 2 == 0:
    return travelTime <= deadline
  return travelTime + diggingTime <= deadline

proc tryAssign(hobbitIndex: int, deadline: int): bool =
  for slotIndex in 0 .. 2 * holeCount - 1:
    if visitedSlots[slotIndex] or not canUseSlot(hobbitIndex, slotIndex, deadline):
      continue
    visitedSlots[slotIndex] = true
    if slotOwner[slotIndex] == -1 or tryAssign(slotOwner[slotIndex], deadline):
      slotOwner[slotIndex] = hobbitIndex
      return true
  return false

proc enoughHobbits(deadline: int, hobbitCount: int, neededCount: int): bool =
  for slotIndex in 0 .. 2 * holeCount - 1:
    slotOwner[slotIndex] = -1
  var assignedCount = 0
  for hobbitIndex in 0 .. hobbitCount - 1:
    for slotIndex in 0 .. 2 * holeCount - 1:
      visitedSlots[slotIndex] = false
    if tryAssign(hobbitIndex, deadline):
      assignedCount += 1
      if assignedCount >= neededCount:
        return true
  return false

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let hobbitCount = nextInt(inputData, scanPos)
  holeCount = nextInt(inputData, scanPos)
  let neededCount = nextInt(inputData, scanPos)
  diggingTime = nextInt(inputData, scanPos)
  travelTimes = newSeq[int](hobbitCount * holeCount)
  var longestTravel = 0
  for hobbitIndex in 0 .. hobbitCount - 1:
    for holeIndex in 0 .. holeCount - 1:
      let travelTime = nextInt(inputData, scanPos)
      travelTimes[hobbitIndex * holeCount + holeIndex] = travelTime
      if travelTime > longestTravel:
        longestTravel = travelTime
  slotOwner = newSeq[int](2 * holeCount)
  visitedSlots = newSeq[bool](2 * holeCount)
  var lowBound = 0
  var highBound = longestTravel + diggingTime + 1
  while lowBound + 1 < highBound:
    let middle = (lowBound + highBound) div 2
    if enoughHobbits(middle, hobbitCount, neededCount):
      highBound = middle
    else:
      lowBound = middle
  appendOutput($highBound)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

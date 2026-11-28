import algorithm

const flushBlockBytes = 1 shl 17

type Cow = object
  gain: int
  deadline: int

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

proc findFreeSlot(parentSlots: var seq[int], requestedSlot: int): int =
  var root = requestedSlot
  while parentSlots[root] != root:
    root = parentSlots[root]
  var current = requestedSlot
  while parentSlots[current] != current:
    let nextSlot = parentSlots[current]
    parentSlots[current] = root
    current = nextSlot
  return root

proc compareGain(leftCow, rightCow: Cow): int =
  if leftCow.gain > rightCow.gain:
    return -1
  if leftCow.gain < rightCow.gain:
    return 1
  return 0

let cowCount = nextInt(inputData, scanPos)
var cows = newSeq[Cow](cowCount)
var latestDeadline = 0
for cowIndex in 0 .. cowCount - 1:
  cows[cowIndex].gain = nextInt(inputData, scanPos)
  cows[cowIndex].deadline = nextInt(inputData, scanPos)
  if cows[cowIndex].deadline > latestDeadline:
    latestDeadline = cows[cowIndex].deadline
cows.sort(compareGain)
var parentSlots = newSeq[int](latestDeadline + 1)
for slotIndex in 0 .. latestDeadline:
  parentSlots[slotIndex] = slotIndex
var totalMilk: int64 = 0
for cow in cows:
  let chosenSlot = findFreeSlot(parentSlots, cow.deadline)
  if chosenSlot > 0:
    totalMilk += int64(cow.gain)
    parentSlots[chosenSlot] = findFreeSlot(parentSlots, chosenSlot - 1)
appendOutput($(totalMilk))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const hashTableSize = 1 shl 22
const countMultiplier = 41
const hashFactor = 2654435761

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

var bitPositions = newSeq[int](1 shl 20)
for bitIndex in 0 .. 19:
  bitPositions[1 shl bitIndex] = bitIndex

var hashKeys = newSeq[int](hashTableSize)
var hashStamps = newSeq[int](hashTableSize)
var currentStamp = 0

proc hashSlot(keyValue: int): int =
  return int((int64(keyValue) * hashFactor) and int64(hashTableSize - 1))

proc insertKey(keyValue: int) =
  var slot = hashSlot(keyValue)
  while hashStamps[slot] == currentStamp and hashKeys[slot] != keyValue:
    slot = (slot + 1) and (hashTableSize - 1)
  if hashStamps[slot] != currentStamp:
    hashStamps[slot] = currentStamp
    hashKeys[slot] = keyValue

proc containsKey(keyValue: int): bool =
  var slot = hashSlot(keyValue)
  while hashStamps[slot] == currentStamp:
    if hashKeys[slot] == keyValue:
      return true
    slot = (slot + 1) and (hashTableSize - 1)
  return false

proc buildSubsetData(values: seq[int], sums: var seq[int], counts: var seq[int8]) =
  let subsetTotal = 1 shl values.len
  sums = newSeq[int](subsetTotal)
  counts = newSeq[int8](subsetTotal)
  var previousGray = 0
  var currentSum = 0
  var currentCount: int8 = 0
  for subsetIndex in 0 .. subsetTotal - 1:
    let grayCode = subsetIndex xor (subsetIndex shr 1)
    if subsetIndex > 0:
      let changedBit = grayCode xor previousGray
      let changedIndex = bitPositions[changedBit]
      if (grayCode and changedBit) != 0:
        currentSum += values[changedIndex]
        currentCount += 1
      else:
        currentSum -= values[changedIndex]
        currentCount -= 1
    sums[subsetIndex] = currentSum
    counts[subsetIndex] = currentCount
    previousGray = grayCode

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let playerCount = nextInt(inputData, scanPos)
  var experiences = newSeq[int](playerCount)
  var totalExperience: int64 = 0
  for playerIndex in 0 .. playerCount - 1:
    experiences[playerIndex] = nextInt(inputData, scanPos)
    totalExperience += int64(experiences[playerIndex])

  var canSplit = false
  if playerCount mod 2 == 0 and (totalExperience and 1) == 0:
    let targetCount = playerCount div 2
    let targetSum = int(totalExperience div 2)
    let firstCount = playerCount div 2
    let secondCount = playerCount - firstCount
    var firstHalf = newSeq[int](firstCount)
    var secondHalf = newSeq[int](secondCount)
    for firstIndex in 0 .. firstCount - 1:
      firstHalf[firstIndex] = experiences[firstIndex]
    for secondIndex in 0 .. secondCount - 1:
      secondHalf[secondIndex] = experiences[firstCount + secondIndex]

    var secondSums: seq[int] = @[]
    var secondCounts: seq[int8] = @[]
    buildSubsetData(secondHalf, secondSums, secondCounts)
    currentStamp += 1
    for subsetIndex in 0 .. (1 shl secondCount) - 1:
      insertKey(secondSums[subsetIndex] * countMultiplier + int(secondCounts[subsetIndex]))

    var firstSums: seq[int] = @[]
    var firstCounts: seq[int8] = @[]
    buildSubsetData(firstHalf, firstSums, firstCounts)
    for subsetIndex in 0 .. (1 shl firstCount) - 1:
      let neededCount = targetCount - int(firstCounts[subsetIndex])
      let neededSum = targetSum - firstSums[subsetIndex]
      if neededCount >= 0 and neededCount <= secondCount and neededSum >= 0:
        if containsKey(neededSum * countMultiplier + neededCount):
          canSplit = true
          break

  appendOutput("Case " & $caseIndex & ": " & (if canSplit: "Yes" else: "No"))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

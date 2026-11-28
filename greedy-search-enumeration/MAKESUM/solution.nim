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

let sumCount = nextInt(inputData, scanPos)
if sumCount == 0:
  appendOutput("1")
  outputBuffer.add '\n'
  stdout.write outputBuffer
  outputBuffer.setLen 0
  quit(0)

var sortedSums = newSeq[int](sumCount)
var largestSum = 0
for sumIndex in 0 .. sumCount - 1:
  sortedSums[sumIndex] = nextInt(inputData, scanPos)
  if sortedSums[sumIndex] > largestSum:
    largestSum = sortedSums[sumIndex]
for sumIndex in 1 .. sumCount - 1:
  let currentSum = sortedSums[sumIndex]
  var previousIndex = sumIndex - 1
  while previousIndex >= 0 and sortedSums[previousIndex] > currentSum:
    sortedSums[previousIndex + 1] = sortedSums[previousIndex]
    previousIndex -= 1
  sortedSums[previousIndex + 1] = currentSum

var totalNumbers = 1
while totalNumbers * (totalNumbers - 1) div 2 < sumCount:
  totalNumbers += 1

var distinctSums = newSeq[int](0)
var targetCounts = newSeq[int](0)
for sumIndex in 0 .. sumCount - 1:
  if sumIndex > 0 and sortedSums[sumIndex] == sortedSums[sumIndex - 1]:
    targetCounts[targetCounts.len - 1] += 1
  else:
    distinctSums.add sortedSums[sumIndex]
    targetCounts.add 1

var sumLookup = newSeq[int](largestSum + 1)
for lookupIndex in 0 .. largestSum:
  sumLookup[lookupIndex] = -1
for distinctIndex in 0 .. distinctSums.len - 1:
  sumLookup[distinctSums[distinctIndex]] = distinctIndex

var usedStamp = newSeq[int](distinctSums.len)
var usedCount = newSeq[int](distinctSums.len)
var trialNumber = 0
var smallestSum = sortedSums[0]
var candidateFirst = 1

while candidateFirst <= smallestSum div 2:
  trialNumber += 1
  var foundNumbers = newSeq[int](1)
  foundNumbers[0] = candidateFirst
  var lookupCursor = 0
  var validTrial = true

  while foundNumbers.len < totalNumbers and validTrial:
    while lookupCursor < distinctSums.len:
      let distinctIndex = lookupCursor
      let alreadyUsed = if usedStamp[distinctIndex] == trialNumber: usedCount[distinctIndex] else: 0
      if targetCounts[distinctIndex] - alreadyUsed > 0:
        break
      lookupCursor += 1
    if lookupCursor >= distinctSums.len:
      validTrial = false
      break
    let chosenSum = distinctSums[lookupCursor]
    let nextNumber = chosenSum - candidateFirst
    if nextNumber < foundNumbers[foundNumbers.len - 1]:
      validTrial = false
      break
    foundNumbers.add nextNumber
    for earlierIndex in 0 .. foundNumbers.len - 2:
      let pairSum = foundNumbers[earlierIndex] + nextNumber
      if pairSum < 0 or pairSum > largestSum:
        validTrial = false
        break
      let distinctIndex = sumLookup[pairSum]
      if distinctIndex < 0:
        validTrial = false
        break
      let alreadyUsed = if usedStamp[distinctIndex] == trialNumber: usedCount[distinctIndex] else: 0
      if targetCounts[distinctIndex] - alreadyUsed <= 0:
        validTrial = false
        break
      if usedStamp[distinctIndex] != trialNumber:
        usedStamp[distinctIndex] = trialNumber
        usedCount[distinctIndex] = 0
      usedCount[distinctIndex] += 1

  if validTrial:
    for numberIndex in 0 .. foundNumbers.len - 1:
      if numberIndex > 0:
        appendOutput(" ")
      appendOutput($foundNumbers[numberIndex])
    outputBuffer.add '\n'
    stdout.write outputBuffer
    outputBuffer.setLen 0
    quit(0)
  candidateFirst += 1

appendOutput("-1")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

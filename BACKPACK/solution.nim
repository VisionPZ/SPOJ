const flushBlockBytes = 1 shl 17
const volumeUnit = 10

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
  let maxVolume = nextInt(inputData, scanPos)
  let goodCount = nextInt(inputData, scanPos)
  var goodVolumes = newSeq[int](goodCount)
  var goodValues = newSeq[int](goodCount)
  var parentIndexes = newSeq[int](goodCount)
  for goodIndex in 0 .. goodCount - 1:
    let rawVolume = nextInt(inputData, scanPos)
    let importance = nextInt(inputData, scanPos)
    goodVolumes[goodIndex] = rawVolume div volumeUnit
    goodValues[goodIndex] = rawVolume * importance
    parentIndexes[goodIndex] = nextInt(inputData, scanPos)
  let capacityUnits = maxVolume div volumeUnit
  var knapsack = newSeq[int](capacityUnits + 1)
  for goodIndex in 0 .. goodCount - 1:
    if parentIndexes[goodIndex] != 0:
      continue
    var attachmentIndexes = newSeq[int]()
    for otherIndex in 0 .. goodCount - 1:
      if parentIndexes[otherIndex] == goodIndex + 1:
        attachmentIndexes.add otherIndex
    let choiceCount = 1 shl attachmentIndexes.len
    var nextKnapsack = knapsack
    for choiceMask in 0 .. choiceCount - 1:
      var choiceVolume = goodVolumes[goodIndex]
      var choiceValue = goodValues[goodIndex]
      for attachmentSlot in 0 .. attachmentIndexes.len - 1:
        if (choiceMask and (1 shl attachmentSlot)) != 0:
          let attachmentIndex = attachmentIndexes[attachmentSlot]
          choiceVolume += goodVolumes[attachmentIndex]
          choiceValue += goodValues[attachmentIndex]
      if choiceVolume > capacityUnits:
        continue
      for capacityLeft in countdown(capacityUnits, choiceVolume):
        let candidate = knapsack[capacityLeft - choiceVolume] + choiceValue
        if candidate > nextKnapsack[capacityLeft]:
          nextKnapsack[capacityLeft] = candidate
    knapsack = nextKnapsack
  appendOutput($(knapsack[capacityUnits]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

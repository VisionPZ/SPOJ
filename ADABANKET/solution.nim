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

let friendCount = nextInt(inputData, scanPos)
var friendshipMatrix = newSeq[int32](friendCount * friendCount)
for rowIndex in 0 .. friendCount - 1:
  for columnIndex in 0 .. friendCount - 1:
    friendshipMatrix[rowIndex * friendCount + columnIndex] = int32(nextInt(inputData, scanPos))

var activeMembers = newSeq[int](friendCount)
for memberIndex in 0 .. friendCount - 1:
  activeMembers[memberIndex] = memberIndex
var activeCount = friendCount
var bestCutValue = high(int32)

while activeCount > 1:
  var phaseIncluded = newSeq[bool](friendCount)
  var phaseWeights = newSeq[int32](friendCount)
  var lastJoined = -1
  var previousJoined = -1
  var phaseCutValue: int32 = 0
  for phaseStep in 0 .. activeCount - 1:
    var chosenMember = -1
    for activeIndex in 0 .. activeCount - 1:
      let candidateMember = activeMembers[activeIndex]
      if not phaseIncluded[candidateMember] and
          (chosenMember == -1 or phaseWeights[candidateMember] > phaseWeights[chosenMember]):
        chosenMember = candidateMember
    phaseIncluded[chosenMember] = true
    phaseCutValue = phaseWeights[chosenMember]
    previousJoined = lastJoined
    lastJoined = chosenMember
    for activeIndex in 0 .. activeCount - 1:
      let candidateMember = activeMembers[activeIndex]
      if not phaseIncluded[candidateMember]:
        phaseWeights[candidateMember] += friendshipMatrix[chosenMember * friendCount + candidateMember]
  if phaseCutValue < bestCutValue:
    bestCutValue = phaseCutValue
  for activeIndex in 0 .. activeCount - 1:
    let candidateMember = activeMembers[activeIndex]
    if candidateMember != lastJoined and candidateMember != previousJoined:
      let mergedWeight = friendshipMatrix[previousJoined * friendCount + candidateMember] +
                         friendshipMatrix[lastJoined * friendCount + candidateMember]
      friendshipMatrix[previousJoined * friendCount + candidateMember] = mergedWeight
      friendshipMatrix[candidateMember * friendCount + previousJoined] = mergedWeight
  var writeIndex = 0
  for activeIndex in 0 .. activeCount - 1:
    let candidateMember = activeMembers[activeIndex]
    if candidateMember != lastJoined:
      activeMembers[writeIndex] = candidateMember
      writeIndex += 1
  activeCount -= 1

appendOutput($(2'i64 * int64(bestCutValue)))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

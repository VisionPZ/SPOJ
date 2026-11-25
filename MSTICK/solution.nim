import algorithm

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

type Stick = object
  lengthValue: int
  weightValue: int

proc compareSticks(leftStick: Stick, rightStick: Stick): int =
  if leftStick.lengthValue < rightStick.lengthValue:
    return -1
  if leftStick.lengthValue > rightStick.lengthValue:
    return 1
  if leftStick.weightValue < rightStick.weightValue:
    return -1
  if leftStick.weightValue > rightStick.weightValue:
    return 1
  return 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let stickCount = nextInt(inputData, scanPos)
  var sticks = newSeq[Stick](stickCount)
  for stickIndex in 0 .. stickCount - 1:
    sticks[stickIndex].lengthValue = nextInt(inputData, scanPos)
    sticks[stickIndex].weightValue = nextInt(inputData, scanPos)
  sticks.sort(compareSticks)
  var chainTails = newSeq[int](stickCount)
  var chainCount = 0
  for stick in sticks:
    let currentWeight = stick.weightValue
    var low = 0
    var high = chainCount
    while low < high:
      let middle = (low + high) div 2
      if chainTails[middle] <= currentWeight:
        low = middle + 1
      else:
        high = middle
    if low == 0:
      var shiftIndex = chainCount
      while shiftIndex > 0:
        chainTails[shiftIndex] = chainTails[shiftIndex - 1]
        shiftIndex -= 1
      chainTails[0] = currentWeight
      chainCount += 1
    else:
      chainTails[low - 1] = currentWeight
  appendOutput($(chainCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

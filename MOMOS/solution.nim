const flushBlockBytes = 1 shl 17
const subsetSwitch = 20

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

proc gcdValues(firstValue, secondValue: int64): int64 =
  var larger = firstValue
  var smaller = secondValue
  while smaller != 0:
    let remainder = larger mod smaller
    larger = smaller
    smaller = remainder
  return larger

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let momoCount = nextInt(inputData, scanPos)
let pigCount = int(nextInt(inputData, scanPos))
var hungerValues = newSeq[int64](pigCount)
for pigIndex in 0 .. pigCount - 1:
  hungerValues[pigIndex] = nextInt(inputData, scanPos)

var insertionIndex = 1
while insertionIndex < hungerValues.len:
  let heldValue = hungerValues[insertionIndex]
  var shiftIndex = insertionIndex - 1
  while shiftIndex >= 0 and hungerValues[shiftIndex] > heldValue:
    hungerValues[shiftIndex + 1] = hungerValues[shiftIndex]
    shiftIndex -= 1
  hungerValues[shiftIndex + 1] = heldValue
  insertionIndex += 1

var leftover: int64 = 0
if pigCount > subsetSwitch:
  var eatenMomos = newSeq[bool](int(momoCount))
  var eatenCount: int64 = 0
  for hunger in hungerValues:
    var position: int64 = 0
    while position < momoCount:
      let momoIndex = int(position)
      if not eatenMomos[momoIndex]:
        eatenMomos[momoIndex] = true
        eatenCount += 1
      position += hunger
  leftover = momoCount - eatenCount
else:
  var keptHungers = newSeq[int64]()
  for hunger in hungerValues:
    var redundant = false
    for kept in keptHungers:
      if hunger mod kept == 0:
        redundant = true
        break
    if not redundant:
      keptHungers.add hunger

  let subsetCount = 1 shl keptHungers.len
  var subsetLcms = newSeq[int64](subsetCount)
  subsetLcms[0] = 1
  var subsetMask = 1
  while subsetMask < subsetCount:
    let lowBit = subsetMask and (-subsetMask)
    var bitIndex = 0
    var probe = lowBit
    while probe > 1:
      probe = probe shr 1
      bitIndex += 1
    let previousMask = subsetMask xor lowBit
    let previousLcm = subsetLcms[previousMask]
    let divisor = keptHungers[bitIndex]
    let common = gcdValues(previousLcm, divisor)
    if previousLcm div common > momoCount div divisor:
      subsetLcms[subsetMask] = momoCount
    else:
      subsetLcms[subsetMask] = previousLcm div common * divisor
    subsetMask += 1

  var eatenCount: int64 = 0
  subsetMask = 1
  while subsetMask < subsetCount:
    let currentLcm = subsetLcms[subsetMask]
    let multipleCount = (momoCount - 1) div currentLcm + 1
    var bitCount = 0
    var probe = subsetMask
    while probe != 0:
      bitCount += probe and 1
      probe = probe shr 1
    if (bitCount and 1) == 1:
      eatenCount += multipleCount
    else:
      eatenCount -= multipleCount
    subsetMask += 1
  leftover = momoCount - eatenCount

appendOutput($leftover)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

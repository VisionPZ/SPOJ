const flushBlockBytes = 1 shl 17
const hashBits = 19
const hashMask = (1 shl hashBits) - 1
const directionNorth = 0
const deltaX = [0, 1, 0, -1]
const deltaY = [1, 0, -1, 0]
const coordinateOffset = 200000
const coordinateBase = 400001

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
while scanPos < inputData.len and inputData[scanPos] <= ' ':
  scanPos += 1
let commandStart = scanPos
while scanPos < inputData.len and inputData[scanPos] > ' ':
  scanPos += 1
let commandString = inputData[commandStart .. scanPos - 1]
let commandCount = commandString.len

var positionX = newSeq[int](commandCount + 1)
var positionY = newSeq[int](commandCount + 1)
var facingDirection = newSeq[int](commandCount + 1)
positionX[0] = 0
positionY[0] = 0
facingDirection[0] = directionNorth
for stepIndex in 0 .. commandCount - 1:
  let beforeX = positionX[stepIndex]
  let beforeY = positionY[stepIndex]
  let facing = facingDirection[stepIndex]
  positionX[stepIndex + 1] = beforeX
  positionY[stepIndex + 1] = beforeY
  facingDirection[stepIndex + 1] = facing
  if commandString[stepIndex] == 'F':
    positionX[stepIndex + 1] = beforeX + deltaX[facing]
    positionY[stepIndex + 1] = beforeY + deltaY[facing]
  elif commandString[stepIndex] == 'L':
    facingDirection[stepIndex + 1] = (facing + 3) mod 4
  else:
    facingDirection[stepIndex + 1] = (facing + 1) mod 4

var suffixX = newSeq[array[4, int]](commandCount + 1)
var suffixY = newSeq[array[4, int]](commandCount + 1)
for direction in 0 .. 3:
  suffixX[commandCount][direction] = 0
  suffixY[commandCount][direction] = 0
var reverseIndex = commandCount - 1
while reverseIndex >= 0:
  for direction in 0 .. 3:
    case commandString[reverseIndex]
    of 'F':
      let shifted = direction
      suffixX[reverseIndex][direction] = deltaX[shifted] + suffixX[reverseIndex + 1][shifted]
      suffixY[reverseIndex][direction] = deltaY[shifted] + suffixY[reverseIndex + 1][shifted]
    of 'L':
      let shifted = (direction + 3) mod 4
      suffixX[reverseIndex][direction] = suffixX[reverseIndex + 1][shifted]
      suffixY[reverseIndex][direction] = suffixY[reverseIndex + 1][shifted]
    else:
      let shifted = (direction + 1) mod 4
      suffixX[reverseIndex][direction] = suffixX[reverseIndex + 1][shifted]
      suffixY[reverseIndex][direction] = suffixY[reverseIndex + 1][shifted]
  reverseIndex -= 1

var seenPositions = newSeq[int64](1 shl hashBits)
var distinctPositions = 0

proc hashPosition(keyValue: int64): int =
  var mixed = keyValue
  mixed = mixed xor (mixed shr 29)
  mixed = mixed * 1000003'i64
  mixed = mixed xor (mixed shr 21)
  return int(mixed and int64(hashMask))

proc addPosition(pointX: int, pointY: int) =
  let packedKey = (int64(pointX + coordinateOffset) * coordinateBase + int64(pointY + coordinateOffset)) + 1
  var slotIndex = hashPosition(packedKey)
  while seenPositions[slotIndex] != 0:
    if seenPositions[slotIndex] == packedKey:
      return
    slotIndex = (slotIndex + 1) and hashMask
  seenPositions[slotIndex] = packedKey
  distinctPositions += 1

for stepIndex in 0 .. commandCount - 1:
  let beforeX = positionX[stepIndex]
  let beforeY = positionY[stepIndex]
  let facing = facingDirection[stepIndex]
  if commandString[stepIndex] == 'F':
    let leftFacing = (facing + 3) mod 4
    let rightFacing = (facing + 1) mod 4
    addPosition(beforeX + suffixX[stepIndex + 1][leftFacing], beforeY + suffixY[stepIndex + 1][leftFacing])
    addPosition(beforeX + suffixX[stepIndex + 1][rightFacing], beforeY + suffixY[stepIndex + 1][rightFacing])
  else:
    addPosition(beforeX + deltaX[facing] + suffixX[stepIndex + 1][facing], beforeY + deltaY[facing] + suffixY[stepIndex + 1][facing])
    let swappedFacing = if commandString[stepIndex] == 'L': (facing + 1) mod 4 else: (facing + 3) mod 4
    addPosition(beforeX + suffixX[stepIndex + 1][swappedFacing], beforeY + suffixY[stepIndex + 1][swappedFacing])

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

appendOutput($distinctPositions)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

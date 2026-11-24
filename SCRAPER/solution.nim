const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const possibleMessage = "It is possible to move the furniture."
const impossibleMessage = "The furniture cannot be moved."

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int64 =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value: int64 = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int64(int(data[i]) - firstDigitValue)
    i += 1
  return value

proc greatestCommonDivisor(firstValue: int64, secondValue: int64): int64 =
  var leftValue = firstValue
  var rightValue = secondValue
  while rightValue != 0:
    let remainder = leftValue mod rightValue
    leftValue = rightValue
    rightValue = remainder
  return leftValue

proc modularInverse(value: int64, modulus: int64): int64 =
  var oldRemainder = value mod modulus
  var remainder = modulus
  var oldCoefficient: int64 = 1
  var coefficient: int64 = 0
  while remainder != 0:
    let quotient = oldRemainder div remainder
    let nextRemainder = oldRemainder - quotient * remainder
    oldRemainder = remainder
    remainder = nextRemainder
    let nextCoefficient = oldCoefficient - quotient * coefficient
    oldCoefficient = coefficient
    coefficient = nextCoefficient
  return ((oldCoefficient mod modulus) + modulus) mod modulus

proc elevatorServesFloor(step: int64, start: int64, floor: int64): bool =
  return floor >= start and (floor - start) mod step == 0

proc elevatorsShareFloor(firstStep: int64, firstStart: int64,
                         secondStep: int64, secondStart: int64,
                         topFloor: int64): bool =
  let divisor = greatestCommonDivisor(firstStep, secondStep)
  let startDifference = secondStart - firstStart
  if startDifference mod divisor != 0:
    return false
  let reducedSecondStep = secondStep div divisor
  let reducedDifference = startDifference div divisor
  var offset: int64 = 0
  if reducedSecondStep > 1:
    let inverseStep = modularInverse(firstStep div divisor, reducedSecondStep)
    offset = (((reducedDifference mod reducedSecondStep) + reducedSecondStep) mod
              reducedSecondStep) * inverseStep mod reducedSecondStep
  let cycleLength = firstStep * reducedSecondStep
  var meetingFloor = firstStart + offset * firstStep
  meetingFloor = meetingFloor mod cycleLength
  let lowestFloor = if firstStart > secondStart: firstStart else: secondStart
  if lowestFloor >= topFloor:
    return false
  if meetingFloor < lowestFloor:
    let missingFloors = lowestFloor - meetingFloor
    let cyclesNeeded = (missingFloors + cycleLength - 1) div cycleLength
    meetingFloor += cyclesNeeded * cycleLength
  return meetingFloor < topFloor

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, i)
for j in 1..caseCount:
  let floorCount = nextInt(inputData, i)
  let elevatorCount = int(nextInt(inputData, i))
  let originFloor = nextInt(inputData, i)
  let targetFloor = nextInt(inputData, i)
  var elevatorStep = newSeq[int64](elevatorCount)
  var elevatorStart = newSeq[int64](elevatorCount)
  for k in 0..<elevatorCount:
    elevatorStep[k] = nextInt(inputData, i)
    elevatorStart[k] = nextInt(inputData, i)
  var reachable = newSeq[bool](elevatorCount)
  var queue = newSeq[int](elevatorCount)
  var queueHead = 0
  var queueTail = 0
  for k in 0..<elevatorCount:
    if elevatorServesFloor(elevatorStep[k],
                           elevatorStart[k], originFloor):
      reachable[k] = true
      queue[queueTail] = k
      queueTail += 1
  var canMove = false
  if originFloor == targetFloor:
    canMove = true
  while not canMove and queueHead < queueTail:
    let k = queue[queueHead]
    queueHead += 1
    if elevatorServesFloor(elevatorStep[k],
                           elevatorStart[k], targetFloor):
      canMove = true
      break
    for l in 0..<elevatorCount:
      if reachable[l]:
        continue
      if elevatorsShareFloor(elevatorStep[k],
                             elevatorStart[k],
                             elevatorStep[l],
                             elevatorStart[l], floorCount):
        reachable[l] = true
        queue[queueTail] = l
        queueTail += 1
  if canMove:
    appendOutput(possibleMessage)
  else:
    appendOutput(impossibleMessage)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const possibleMessage = "It is possible to move the furniture."
const impossibleMessage = "The furniture cannot be moved."

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int64 =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value: int64 = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int64(int(data[position]) - firstDigitValue)
    position += 1
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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1..caseCount:
  let floorCount = nextInt(inputData, scanPos)
  let elevatorCount = int(nextInt(inputData, scanPos))
  let originFloor = nextInt(inputData, scanPos)
  let targetFloor = nextInt(inputData, scanPos)
  var elevatorStep = newSeq[int64](elevatorCount)
  var elevatorStart = newSeq[int64](elevatorCount)
  for elevatorIndex in 0..<elevatorCount:
    elevatorStep[elevatorIndex] = nextInt(inputData, scanPos)
    elevatorStart[elevatorIndex] = nextInt(inputData, scanPos)
  var reachable = newSeq[bool](elevatorCount)
  var queue = newSeq[int](elevatorCount)
  var queueHead = 0
  var queueTail = 0
  for elevatorIndex in 0..<elevatorCount:
    if elevatorServesFloor(elevatorStep[elevatorIndex],
                           elevatorStart[elevatorIndex], originFloor):
      reachable[elevatorIndex] = true
      queue[queueTail] = elevatorIndex
      queueTail += 1
  var canMove = false
  if originFloor == targetFloor:
    canMove = true
  while not canMove and queueHead < queueTail:
    let currentElevator = queue[queueHead]
    queueHead += 1
    if elevatorServesFloor(elevatorStep[currentElevator],
                           elevatorStart[currentElevator], targetFloor):
      canMove = true
      break
    for otherElevator in 0..<elevatorCount:
      if reachable[otherElevator]:
        continue
      if elevatorsShareFloor(elevatorStep[currentElevator],
                             elevatorStart[currentElevator],
                             elevatorStep[otherElevator],
                             elevatorStart[otherElevator], floorCount):
        reachable[otherElevator] = true
        queue[queueTail] = otherElevator
        queueTail += 1
  if canMove:
    appendOutput(possibleMessage)
  else:
    appendOutput(impossibleMessage)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const quadraticTimeLimit: int64 = 100000000
const linearTimeLimit: int64 = 10000000000

type ShipState = object
  startX: int64
  startY: int64
  velocityX: int64
  velocityY: int64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

proc nextDirection(data: string, pos: var int): int =
  while pos < data.len and data[pos] != 'n' and data[pos] != 's' and
        data[pos] != 'e' and data[pos] != 'w':
    pos += 1
  let initialLetter = data[pos]
  while pos < data.len and data[pos] >= 'a' and data[pos] <= 'z':
    pos += 1
  case initialLetter
  of 'n': return 0
  of 's': return 1
  of 'e': return 2
  else: return 3

proc velocityXFrom(directionCode: int, speedValue: int64): int64 =
  case directionCode
  of 2: return speedValue
  of 3: return -speedValue
  else: return 0

proc velocityYFrom(directionCode: int, speedValue: int64): int64 =
  case directionCode
  of 0: return speedValue
  of 1: return -speedValue
  else: return 0

proc twiceAreaAt(timeValue: int64, squareCoefficient: int64,
                 linearCoefficient: int64, constantCoefficient: int64): int64 =
  let signedArea = squareCoefficient * timeValue * timeValue +
                   linearCoefficient * timeValue + constantCoefficient
  if signedArea < 0:
    return -signedArea
  return signedArea

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let searchLimit = int64(nextInt(inputData, scanPos))
  var ships: seq[ShipState] = @[]
  for shipIndex in 1 .. 3:
    var ship: ShipState
    ship.startX = int64(nextInt(inputData, scanPos))
    ship.startY = int64(nextInt(inputData, scanPos))
    let directionCode = nextDirection(inputData, scanPos)
    let speedValue = int64(nextInt(inputData, scanPos))
    ship.velocityX = velocityXFrom(directionCode, speedValue)
    ship.velocityY = velocityYFrom(directionCode, speedValue)
    ships.add ship
  let relativeX = ships[1].startX - ships[0].startX
  let relativeY = ships[1].startY - ships[0].startY
  let otherX = ships[2].startX - ships[0].startX
  let otherY = ships[2].startY - ships[0].startY
  let velocityX = ships[1].velocityX - ships[0].velocityX
  let velocityY = ships[1].velocityY - ships[0].velocityY
  let otherVelocityX = ships[2].velocityX - ships[0].velocityX
  let otherVelocityY = ships[2].velocityY - ships[0].velocityY
  let constantCoefficient = relativeX * otherY - relativeY * otherX
  let squareCoefficient = velocityX * otherVelocityY - velocityY * otherVelocityX
  let linearCoefficient = (velocityX * otherY - velocityY * otherX) +
                          (relativeX * otherVelocityY - relativeY * otherVelocityX)
  let allowedTwiceArea = 2 * searchLimit
  var safeTime = quadraticTimeLimit
  if squareCoefficient == 0:
    safeTime = linearTimeLimit
  var lowTime: int64 = 0
  var highTime: int64 = 1
  while highTime < safeTime and
        twiceAreaAt(highTime, squareCoefficient, linearCoefficient,
                    constantCoefficient) <= allowedTwiceArea:
    highTime *= 2
  if highTime > safeTime:
    highTime = safeTime
  while lowTime + 1 < highTime:
    let middleTime = lowTime + (highTime - lowTime) div 2
    if twiceAreaAt(middleTime, squareCoefficient, linearCoefficient,
                   constantCoefficient) <= allowedTwiceArea:
      lowTime = middleTime
    else:
      highTime = middleTime
  appendOutput("Scenario #")
  appendOutput($caseIndex)
  appendOutput(": ")
  appendOutput($lowTime)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

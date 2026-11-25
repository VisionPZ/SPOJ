const flushBlockBytes = 1 shl 17

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let totalCopies = nextInt(inputData, scanPos)
let truckCapacity = nextInt(inputData, scanPos)
let checkpointCount = nextInt(inputData, scanPos)
let allowedReturns = nextInt(inputData, scanPos)
let departureCount = allowedReturns + 1

var copiesLeavingDepot = totalCopies
if truckCapacity <= totalCopies div departureCount:
  copiesLeavingDepot = truckCapacity * departureCount

var deliveredCopies = copiesLeavingDepot
var checkpointsRemaining = checkpointCount
while checkpointsRemaining > 0 and deliveredCopies > 0:
  let crossingLoad = (deliveredCopies + truckCapacity - 1) div truckCapacity
  let previousBandTop = (crossingLoad - 1) * truckCapacity
  var equalLoadSteps = (deliveredCopies - previousBandTop + crossingLoad - 1) div crossingLoad
  if equalLoadSteps > checkpointsRemaining:
    equalLoadSteps = checkpointsRemaining
  deliveredCopies = deliveredCopies - equalLoadSteps * crossingLoad
  checkpointsRemaining = checkpointsRemaining - equalLoadSteps

appendOutput($deliveredCopies)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

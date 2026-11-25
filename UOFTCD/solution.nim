const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc holdingCost(momentTimes: seq[int64], momentForces: seq[int64], movieLength: int64, handThreshold: int64, leaveThreshold: int64, skippedMoment: int): int64 =
  var frightLevel: int64 = 0
  var totalHeld: int64 = 0
  for momentIndex in 0 .. momentTimes.len - 1:
    if momentIndex != skippedMoment:
      frightLevel = frightLevel + momentForces[momentIndex]
      if frightLevel < 0:
        frightLevel = 0
    if frightLevel >= leaveThreshold:
      return totalHeld
    if frightLevel >= handThreshold:
      let nextTime = if momentIndex + 1 < momentTimes.len: momentTimes[momentIndex + 1] else: movieLength
      totalHeld = totalHeld + (nextTime - momentTimes[momentIndex])
  return totalHeld

let movieCount = nextInt(inputData, scanPos)
for movieIndex in 0 .. movieCount - 1:
  let movieLength = nextInt(inputData, scanPos)
  let momentCount = nextInt(inputData, scanPos)
  let handThreshold = nextInt(inputData, scanPos)
  let leaveThreshold = nextInt(inputData, scanPos)
  var momentTimes = newSeq[int64](momentCount)
  var momentForces = newSeq[int64](momentCount)
  for momentIndex in 0 .. momentCount - 1:
    momentTimes[momentIndex] = int64(nextInt(inputData, scanPos))
    momentForces[momentIndex] = int64(nextInt(inputData, scanPos))
  var bestCost = holdingCost(momentTimes, momentForces, int64(movieLength), int64(handThreshold), int64(leaveThreshold), -1)
  for skipIndex in 0 .. momentCount - 1:
    let candidateCost = holdingCost(momentTimes, momentForces, int64(movieLength), int64(handThreshold), int64(leaveThreshold), skipIndex)
    if candidateCost < bestCost:
      bestCost = candidateCost
  appendOutput($bestCost)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0

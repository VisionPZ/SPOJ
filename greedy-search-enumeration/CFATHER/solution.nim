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

let studentCount = nextInt(inputData, scanPos)
var pointTotals = newSeq[int](studentCount)
for studentIndex in 0 .. studentCount - 1:
  pointTotals[studentIndex] = nextInt(inputData, scanPos)

let targetPoints = pointTotals[0] - 1
var losses = newSeq[int](studentCount)
var capacities = newSeq[int](studentCount)
var lossCount = 0
var capacityCount = 0
for studentIndex in 1 .. studentCount - 1:
  if pointTotals[studentIndex] > targetPoints:
    losses[lossCount] = pointTotals[studentIndex] - targetPoints
    lossCount += 1
  else:
    capacities[capacityCount] = targetPoints - pointTotals[studentIndex]
    capacityCount += 1
losses.setLen(lossCount)
capacities.setLen(capacityCount)

if lossCount == 0:
  appendOutput("0\n")
elif capacityCount == 0:
  appendOutput("impossible\n")
else:
  proc compareLosses(left: int, right: int): int =
    if left > right: return -1
    if left < right: return 1
    return 0

  proc compareCapacities(left: int, right: int): int =
    if left < right: return -1
    if left > right: return 1
    return 0

  losses.sort(compareLosses)
  capacities.sort(compareCapacities)
  var lossPrefix = newSeq[int64](lossCount + 1)
  for index in 0 .. lossCount - 1:
    lossPrefix[index + 1] = lossPrefix[index] + int64(losses[index])
  var capacityPrefix = newSeq[int64](capacityCount + 1)
  for index in 0 .. capacityCount - 1:
    capacityPrefix[index + 1] = capacityPrefix[index] + int64(capacities[index])

  proc canTransfer(maxTransfer: int): bool =
    for giverCount in 1 .. lossCount:
      let perReceiver = int64(maxTransfer) * int64(giverCount)
      var low = 0
      var high = capacityCount
      while low < high:
        let middle = (low + high) div 2
        if int64(capacities[middle]) <= perReceiver:
          low = middle + 1
        else:
          high = middle
      let available = capacityPrefix[low] + perReceiver * int64(capacityCount - low)
      if lossPrefix[giverCount] > available:
        return false
    return true

  var lowBound = 0
  var highBound = losses[0]
  if not canTransfer(highBound):
    appendOutput("impossible\n")
  else:
    while lowBound < highBound:
      let middle = (lowBound + highBound) div 2
      if canTransfer(middle):
        highBound = middle
      else:
        lowBound = middle + 1
    appendOutput($lowBound & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0

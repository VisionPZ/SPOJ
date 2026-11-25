import algorithm

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
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

proc hasMoreData(data: string, pos: var int): bool =
  var probe = pos
  while probe < data.len and (data[probe] < '0' or data[probe] > '9') and data[probe] != '-':
    probe += 1
  if probe < data.len:
    pos = probe
    return true
  return false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type OilEvent = object
  numerator: int64
  denominator: int64
  eventKind: int
  weight: int64

proc compareEvents(first: OilEvent, second: OilEvent): int =
  let leftProduct = first.numerator * second.denominator
  let rightProduct = second.numerator * first.denominator
  if leftProduct < rightProduct:
    return -1
  elif leftProduct > rightProduct:
    return 1
  elif first.eventKind < second.eventKind:
    return -1
  elif first.eventKind > second.eventKind:
    return 1
  return 0

while hasMoreData(inputData, scanPos):
  let depositCount = nextInt(inputData, scanPos)
  var leftEnds = newSeq[int](depositCount)
  var rightEnds = newSeq[int](depositCount)
  var depths = newSeq[int](depositCount)
  for depositIndex in 0 .. depositCount - 1:
    let firstEnd = nextInt(inputData, scanPos)
    let secondEnd = nextInt(inputData, scanPos)
    if firstEnd <= secondEnd:
      leftEnds[depositIndex] = firstEnd
      rightEnds[depositIndex] = secondEnd
    else:
      leftEnds[depositIndex] = secondEnd
      rightEnds[depositIndex] = firstEnd
    depths[depositIndex] = nextInt(inputData, scanPos)
  var bestTotal: int64 = 0
  var events = newSeq[OilEvent](2 * depositCount)
  for anchorIndex in 0 .. depositCount - 1:
    for anchorSide in 0 .. 1:
      var anchorX = leftEnds[anchorIndex]
      if anchorSide == 1:
        anchorX = rightEnds[anchorIndex]
      let anchorY = depths[anchorIndex]
      events.setLen(2 * depositCount)
      var alwaysHit: int64 = 0
      var eventCount = 0
      for depositIndex in 0 .. depositCount - 1:
        let depthGap = depths[depositIndex] - anchorY
        let depositWidth = int64(rightEnds[depositIndex] - leftEnds[depositIndex])
        if depthGap == 0:
          if leftEnds[depositIndex] <= anchorX and anchorX <= rightEnds[depositIndex]:
            alwaysHit += depositWidth
          continue
        var lowerNumerator = 0
        var upperNumerator = 0
        var denominator = depthGap
        if depthGap > 0:
          lowerNumerator = leftEnds[depositIndex] - anchorX
          upperNumerator = rightEnds[depositIndex] - anchorX
        else:
          lowerNumerator = anchorX - rightEnds[depositIndex]
          upperNumerator = anchorX - leftEnds[depositIndex]
          denominator = -depthGap
        events[eventCount] = OilEvent(numerator: int64(lowerNumerator),
                                      denominator: int64(denominator),
                                      eventKind: 0, weight: depositWidth)
        eventCount += 1
        events[eventCount] = OilEvent(numerator: int64(upperNumerator),
                                      denominator: int64(denominator),
                                      eventKind: 1, weight: -depositWidth)
        eventCount += 1
      events.setLen(eventCount)
      events.sort(compareEvents)
      var currentTotal = alwaysHit
      if currentTotal > bestTotal:
        bestTotal = currentTotal
      for eventIndex in 0 .. eventCount - 1:
        currentTotal += events[eventIndex].weight
        if currentTotal > bestTotal:
          bestTotal = currentTotal
  appendOutput($bestTotal)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0

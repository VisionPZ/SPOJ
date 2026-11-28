const flushBlockBytes = 1 shl 17

type HallEvent = tuple[eventTime: int, dancerDelta: int]

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc sortEvents(events: var seq[HallEvent]) =
  for rightIndex in 1 .. events.high:
    let heldEvent = events[rightIndex]
    var leftIndex = rightIndex - 1
    while leftIndex >= 0 and events[leftIndex].eventTime > heldEvent.eventTime:
      events[leftIndex + 1] = events[leftIndex]
      leftIndex -= 1
    events[leftIndex + 1] = heldEvent

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let visitorCount = nextInt(inputData, scanPos)
  var hallEvents = newSeq[HallEvent](2 * visitorCount)
  for visitorIndex in 0 .. visitorCount - 1:
    let enterTime = nextInt(inputData, scanPos)
    let leaveTime = nextInt(inputData, scanPos)
    hallEvents[2 * visitorIndex] = (enterTime, 1)
    hallEvents[2 * visitorIndex + 1] = (leaveTime, -1)
  sortEvents(hallEvents)
  var dancersNow = 0
  var peakDancers = 0
  for eventIndex in 0 .. hallEvents.high:
    dancersNow += hallEvents[eventIndex].dancerDelta
    if dancersNow > peakDancers:
      peakDancers = dancersNow
  appendOutput($peakDancers)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

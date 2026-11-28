const flushBlockBytes = 1 shl 17
const impossibleTime = 1000000000

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

proc departureTime(arrival: int, intersection: int, greenTimes: seq[int], redTimes: seq[int]): int =
  let cycle = greenTimes[intersection] + redTimes[intersection]
  if cycle == 0:
    return arrival
  let phase = arrival mod cycle
  if phase < greenTimes[intersection]:
    return arrival
  return arrival + (cycle - phase)

let streetCount = nextInt(inputData, scanPos)
let intersectionCount = nextInt(inputData, scanPos)
var streets = newSeq[seq[tuple[target: int, travel: int]]](intersectionCount + 1)
for streetIndex in 0 .. streetCount - 1:
  let startPoint = nextInt(inputData, scanPos)
  let endPoint = nextInt(inputData, scanPos)
  let travelTime = nextInt(inputData, scanPos)
  streets[startPoint].add((endPoint, travelTime))
  streets[endPoint].add((startPoint, travelTime))
var greenTimes = newSeq[int](intersectionCount + 1)
var redTimes = newSeq[int](intersectionCount + 1)
for intersection in 1 .. intersectionCount:
  greenTimes[intersection] = nextInt(inputData, scanPos)
  redTimes[intersection] = nextInt(inputData, scanPos)
var bestTimes = newSeq[int](intersectionCount + 1)
var settled = newSeq[bool](intersectionCount + 1)
for intersection in 1 .. intersectionCount:
  bestTimes[intersection] = impossibleTime
  settled[intersection] = false
bestTimes[1] = 0
for step in 0 .. intersectionCount - 1:
  var current = 0
  for intersection in 1 .. intersectionCount:
    if not settled[intersection] and (current == 0 or bestTimes[intersection] < bestTimes[current]):
      current = intersection
  if current == 0 or bestTimes[current] >= impossibleTime:
    break
  settled[current] = true
  let leaveAt = departureTime(bestTimes[current], current, greenTimes, redTimes)
  for edge in streets[current]:
    let arriveAt = leaveAt + edge.travel
    if arriveAt < bestTimes[edge.target]:
      bestTimes[edge.target] = arriveAt
appendOutput($bestTimes[intersectionCount])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const infiniteCost = 1 shl 28
const trackCost = 1
const offTrackCost = 2

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

proc nextTrack(data: string, pos: var int, trackLength: int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  for position in 0 .. trackLength - 1:
    result.add data[pos]
    pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var onTrackCosts = newSeq[int](0)
var offTrackCosts = newSeq[int](0)

proc solveRace(track: string, bulletLimit: int): string =
  let trackLength = track.len
  var wallCount = 0
  for symbol in track:
    if symbol == '#': wallCount += 1
  let maxShots = min(bulletLimit, wallCount)
  let stride = maxShots + 1
  let stateCapacity = trackLength * stride
  onTrackCosts.setLen(stateCapacity)
  offTrackCosts.setLen(stateCapacity)
  for stateIndex in 0 .. stateCapacity - 1:
    onTrackCosts[stateIndex] = infiniteCost
    offTrackCosts[stateIndex] = infiniteCost
  onTrackCosts[0] = 0
  for position in 0 .. trackLength - 1:
    let currentBase = position * stride
    if track[position] != '#':
      for shotCount in 0 .. maxShots:
        let candidate = offTrackCosts[currentBase + shotCount] + offTrackCost
        if candidate < onTrackCosts[currentBase + shotCount]:
          onTrackCosts[currentBase + shotCount] = candidate
    for shotCount in 0 .. maxShots:
      let candidate = onTrackCosts[currentBase + shotCount] + offTrackCost
      if candidate < offTrackCosts[currentBase + shotCount]:
        offTrackCosts[currentBase + shotCount] = candidate
    if position == trackLength - 1: break
    let nextBase = currentBase + stride
    for shotCount in 0 .. maxShots:
      let onCandidate = onTrackCosts[currentBase + shotCount] + trackCost
      if track[position + 1] == '#':
        if shotCount < maxShots and onCandidate < onTrackCosts[nextBase + shotCount + 1]:
          onTrackCosts[nextBase + shotCount + 1] = onCandidate
      elif onCandidate < onTrackCosts[nextBase + shotCount]:
        onTrackCosts[nextBase + shotCount] = onCandidate
      let offCandidate = offTrackCosts[currentBase + shotCount] + offTrackCost
      if offCandidate < offTrackCosts[nextBase + shotCount]:
        offTrackCosts[nextBase + shotCount] = offCandidate
  var bestTime = infiniteCost
  let finalBase = (trackLength - 1) * stride
  for shotCount in 0 .. maxShots:
    if onTrackCosts[finalBase + shotCount] < bestTime:
      bestTime = onTrackCosts[finalBase + shotCount]
  if bestTime >= infiniteCost:
    return "Impossible"
  return $bestTime

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let trackLength = nextInt(inputData, scanPos)
  let bulletLimit = nextInt(inputData, scanPos)
  let track = nextTrack(inputData, scanPos, trackLength)
  appendOutput(solveRace(track, bulletLimit))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

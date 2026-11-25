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

let wagonCount = nextInt(inputData, scanPos)
let trackLimit = nextInt(inputData, scanPos)
var lastWagons = newSeq[int](trackLimit)
var usedTracks = 0
var inputTracks = newSeq[int](wagonCount)
var labelTracks = newSeq[int](wagonCount + 1)
for wagonIndex in 0 .. wagonCount - 1:
  let wagonLabel = nextInt(inputData, scanPos)
  var lowTrack = 0
  var highTrack = usedTracks
  while lowTrack < highTrack:
    let middleTrack = (lowTrack + highTrack) div 2
    if lastWagons[middleTrack] < wagonLabel:
      highTrack = middleTrack
    else:
      lowTrack = middleTrack + 1
  if lowTrack == usedTracks:
    lastWagons[lowTrack] = wagonLabel
    usedTracks += 1
  else:
    lastWagons[lowTrack] = wagonLabel
  let trackNumber = lowTrack + 1
  inputTracks[wagonIndex] = trackNumber
  labelTracks[wagonLabel] = trackNumber

for wagonIndex in 0 .. wagonCount - 1:
  appendOutput($inputTracks[wagonIndex])
  if wagonIndex == wagonCount - 1:
    outputBuffer.add '\n'
  else:
    outputBuffer.add ' '
for wagonLabel in 1 .. wagonCount:
  appendOutput($labelTracks[wagonLabel])
  if wagonLabel == wagonCount:
    outputBuffer.add '\n'
  else:
    outputBuffer.add ' '
stdout.write outputBuffer
outputBuffer.setLen 0

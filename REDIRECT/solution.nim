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

let tileCount = nextInt(inputData, scanPos)
let turnCount = int64(nextInt(inputData, scanPos))
var jumpLengths = newSeq[int64](tileCount + 2)
for tileIndex in 1 .. tileCount:
  jumpLengths[tileIndex] = int64(nextInt(inputData, scanPos))
let chargedTile = nextInt(inputData, scanPos)
let boardEnd = int64(tileCount)

var reachableFromStart = newSeq[bool](tileCount + 2)
reachableFromStart[1] = true
for tileIndex in 1 .. tileCount:
  if reachableFromStart[tileIndex]:
    let firstTarget = int64(tileIndex) + jumpLengths[tileIndex]
    let secondTarget = firstTarget + 1
    if firstTarget >= 1 and firstTarget <= boardEnd:
      reachableFromStart[int(firstTarget)] = true
    if secondTarget >= 1 and secondTarget <= boardEnd:
      reachableFromStart[int(secondTarget)] = true

var reachesCharged = newSeq[bool](tileCount + 2)
var backwardTile = tileCount
while backwardTile >= 1:
  if backwardTile == chargedTile:
    reachesCharged[backwardTile] = true
  else:
    let firstTarget = int64(backwardTile) + jumpLengths[backwardTile]
    let secondTarget = firstTarget + 1
    if firstTarget >= 1 and firstTarget <= boardEnd and reachesCharged[int(firstTarget)]:
      reachesCharged[backwardTile] = true
    if secondTarget >= 1 and secondTarget <= boardEnd and reachesCharged[int(secondTarget)]:
      reachesCharged[backwardTile] = true
  backwardTile -= 1

let backTarget = int64(chargedTile) - jumpLengths[chargedTile]
var repeatingCycle = false
if reachableFromStart[chargedTile] and backTarget >= 1 and reachesCharged[int(backTarget)]:
  repeatingCycle = true

if repeatingCycle:
  appendOutput("WINNER\n")
else:
  var forwardOnly = newSeq[int](tileCount + 2)
  var scanTile = tileCount
  while scanTile >= 1:
    var bestSteps = 0
    let firstTarget = int64(scanTile) + jumpLengths[scanTile]
    let secondTarget = firstTarget + 1
    if firstTarget >= 1 and firstTarget <= boardEnd:
      bestSteps = 1 + forwardOnly[int(firstTarget)]
    if secondTarget >= 1 and secondTarget <= boardEnd and 1 + forwardOnly[int(secondTarget)] > bestSteps:
      bestSteps = 1 + forwardOnly[int(secondTarget)]
    forwardOnly[scanTile] = bestSteps
    scanTile -= 1
  var fullPlay = newSeq[int](tileCount + 2)
  scanTile = tileCount
  while scanTile >= 1:
    var bestSteps = 0
    let firstTarget = int64(scanTile) + jumpLengths[scanTile]
    let secondTarget = firstTarget + 1
    if firstTarget >= 1 and firstTarget <= boardEnd:
      bestSteps = 1 + fullPlay[int(firstTarget)]
    if secondTarget >= 1 and secondTarget <= boardEnd and 1 + fullPlay[int(secondTarget)] > bestSteps:
      bestSteps = 1 + fullPlay[int(secondTarget)]
    if scanTile == chargedTile and backTarget >= 1 and 1 + forwardOnly[int(backTarget)] > bestSteps:
      bestSteps = 1 + forwardOnly[int(backTarget)]
    fullPlay[scanTile] = bestSteps
    scanTile -= 1
  if int64(fullPlay[1]) >= turnCount:
    appendOutput("WINNER\n")
  else:
    appendOutput("LOSER\n")
stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const cycleLength = 30
const risingHalf = 16
const fallingHalf = 14

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  if pos >= data.len:
    return -1
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

var moonCycle = newSeq[int](cycleLength)
for dayIndex in 0 .. risingHalf - 1:
  moonCycle[dayIndex] = dayIndex
for dayIndex in 0 .. fallingHalf - 1:
  moonCycle[risingHalf + dayIndex] = fallingHalf - dayIndex

while true:
  let dayCount = nextInt(inputData, scanPos)
  if dayCount < 0:
    break
  var moonRecord = newSeq[int](dayCount)
  for recordIndex in 0 .. dayCount - 1:
    moonRecord[recordIndex] = nextInt(inputData, scanPos)
  var decidedDirection = 0
  var mixedDirections = 0
  for phase in 0 .. cycleLength - 1:
    var matches = 1
    for recordIndex in 0 .. dayCount - 1:
      if moonCycle[(phase + recordIndex) mod cycleLength] != moonRecord[recordIndex]:
        matches = 0
        break
    if matches == 0:
      continue
    let lastSize = moonCycle[(phase + dayCount - 1) mod cycleLength]
    let nextSize = moonCycle[(phase + dayCount) mod cycleLength]
    let direction = if nextSize > lastSize: 1 else: -1
    if decidedDirection == 0:
      decidedDirection = direction
    elif decidedDirection != direction:
      mixedDirections = 1
      break
  if mixedDirections == 1 or decidedDirection == 0:
    appendOutput("-1\n")
  elif decidedDirection > 0:
    appendOutput("CRECIENTE\n")
  else:
    appendOutput("MENGUANTE\n")
stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const cycleLength = 30
const peakDay = 15

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

proc moonSize(dayPhase: int): int =
  if dayPhase <= peakDay:
    return dayPhase
  return cycleLength - dayPhase

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let dayCount = nextInt(inputData, scanPos)
var observed = newSeq[int](dayCount)
for dayIndex in 0 .. dayCount - 1:
  observed[dayIndex] = nextInt(inputData, scanPos)

var sawIncrease = false
var sawDecrease = false
for startPhase in 0 .. cycleLength - 1:
  var matches = true
  for dayIndex in 0 .. dayCount - 1:
    if moonSize((startPhase + dayIndex) mod cycleLength) != observed[dayIndex]:
      matches = false
      break
  if not matches:
    continue
  let lastSize = moonSize((startPhase + dayCount - 1) mod cycleLength)
  let nextSize = moonSize((startPhase + dayCount) mod cycleLength)
  if nextSize > lastSize:
    sawIncrease = true
  else:
    sawDecrease = true

if sawIncrease and not sawDecrease:
  appendOutput("CRECIENTE")
elif sawDecrease and not sawIncrease:
  appendOutput("MENGUANTE")
else:
  appendOutput("-1")
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

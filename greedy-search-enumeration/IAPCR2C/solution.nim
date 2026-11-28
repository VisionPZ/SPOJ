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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let studentCount = nextInt(inputData, scanPos)
  let workingCount = nextInt(inputData, scanPos)
  var canUse = newSeq[bool](studentCount + 2)
  for computerIndex in 0 .. workingCount - 1:
    let computerSeat = nextInt(inputData, scanPos)
    var firstSeat = computerSeat - 1
    if firstSeat < 1:
      firstSeat = 1
    var lastSeat = computerSeat + 1
    if lastSeat > studentCount:
      lastSeat = studentCount
    var seat = firstSeat
    while seat <= lastSeat:
      canUse[seat] = true
      seat += 1
  var happyStudents = 0
  for seat in 1 .. studentCount:
    if canUse[seat]:
      happyStudents += 1
  appendOutput("Case ")
  appendOutput($(caseIndex + 1))
  appendOutput(": ")
  appendOutput($happyStudents)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const maxDiskCount = 60

proc nextInt64(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var diskLabels: array[maxDiskCount + 1, string]
for diskNumber in 1 .. maxDiskCount:
  diskLabels[diskNumber] = $diskNumber

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var scanPos = 0
let caseCount = int(nextInt64(inputData, scanPos))
for caseIndex in 0 ..< caseCount:
  let diskCount = int(nextInt64(inputData, scanPos))
  let stepCount = nextInt64(inputData, scanPos)
  var diskPeg: array[maxDiskCount + 1, int]
  for diskNumber in 1 .. diskCount:
    let firstMoveStep = 1'i64 shl (diskNumber - 1)
    var moveCount: int64 = 0
    if stepCount >= firstMoveStep:
      moveCount = (stepCount - firstMoveStep) div (1'i64 shl diskNumber) + 1
    let cycleIndex = int(moveCount mod 3)
    let turnIsForward = (diskCount - diskNumber) mod 2 == 0
    if cycleIndex == 0:
      diskPeg[diskNumber] = 1
    elif turnIsForward:
      diskPeg[diskNumber] = cycleIndex + 1
    else:
      diskPeg[diskNumber] = 4 - cycleIndex
  for pegNumber in 1 .. 3:
    appendOutput($pegNumber)
    appendOutput(":")
    var firstDiskOnPeg = true
    for diskNumber in countdown(diskCount, 1):
      if diskPeg[diskNumber] == pegNumber:
        if firstDiskOnPeg:
          appendOutput(" ")
          firstDiskOnPeg = false
        else:
          appendOutput("|")
        appendOutput(diskLabels[diskNumber])
    appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0

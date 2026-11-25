const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let carCount = nextInt(inputData, scanPos)
var arrivalOrder = newSeq[int](carCount)
for arrivalIndex in 0 .. carCount - 1:
  arrivalOrder[arrivalIndex] = nextInt(inputData, scanPos)
var desiredOrder = newSeq[int](carCount)
for desiredIndex in 0 .. carCount - 1:
  desiredOrder[desiredIndex] = nextInt(inputData, scanPos)

var maneuverStack = newSeq[int]()
var nextArrivalIndex = 0
var operationText = ""
var possible = true
for desiredCar in desiredOrder:
  while (maneuverStack.len == 0 or maneuverStack[maneuverStack.len - 1] != desiredCar) and nextArrivalIndex < carCount:
    operationText.add "PUSH\n"
    maneuverStack.add arrivalOrder[nextArrivalIndex]
    nextArrivalIndex += 1
  if maneuverStack.len > 0 and maneuverStack[maneuverStack.len - 1] == desiredCar:
    operationText.add "POP\n"
    maneuverStack.setLen(maneuverStack.len - 1)
  else:
    possible = false
    break

if possible:
  appendOutput(operationText)
else:
  appendOutput("IMPOSSIVEL\n")
stdout.write outputBuffer
outputBuffer.setLen 0

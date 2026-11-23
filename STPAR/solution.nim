const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let truckCount = nextInt(inputData, scanPos)
  if truckCount == 0:
    break
  var stack: seq[int] = @[]
  var nextExpected = 1
  for arrivalIndex in 0..<truckCount:
    let arrivingTruck = nextInt(inputData, scanPos)
    stack.add arrivingTruck
    while stack.len > 0 and stack[stack.len - 1] == nextExpected:
      stack.setLen(stack.len - 1)
      nextExpected += 1
  if nextExpected == truckCount + 1:
    appendOutput("yes")
  else:
    appendOutput("no")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

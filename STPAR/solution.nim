const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let truckCount = nextInt(inputData, i)
  if truckCount == 0:
    break
  var stack: seq[int] = @[]
  var nextExpected = 1
  for j in 0..<truckCount:
    let arrivingTruck = nextInt(inputData, i)
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

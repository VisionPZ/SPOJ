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

let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let originalValue = nextInt(inputData, scanPos)
  var nextRepunit = 9
  while nextRepunit <= originalValue:
    nextRepunit = nextRepunit * 10 + 9
  var difference = int64(nextRepunit) - 2 * int64(originalValue)
  if difference < 0:
    difference = -difference
  if difference <= 1:
    appendOutput("-1")
  else:
    var smallestDivisor = difference
    var candidate = 3
    while int64(candidate) * int64(candidate) <= difference:
      if difference mod int64(candidate) == 0:
        smallestDivisor = int64(candidate)
        break
      candidate += 2
    appendOutput($smallestDivisor)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

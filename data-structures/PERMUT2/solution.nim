const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maximumPermutationLength = 100000

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var permValues = newSeq[int](maximumPermutationLength + 1)

while true:
  let lengthCount = nextInt(inputData, scanPos)
  if lengthCount == 0: break
  for position in 1 .. lengthCount:
    permValues[position] = nextInt(inputData, scanPos)
  var isAmbiguous = true
  for position in 1 .. lengthCount:
    if permValues[permValues[position]] != position:
      isAmbiguous = false
      break
  if isAmbiguous:
    appendOutput("ambiguous\n")
  else:
    appendOutput("not ambiguous\n")

stdout.write outputBuffer
outputBuffer.setLen 0

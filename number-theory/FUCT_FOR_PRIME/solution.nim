const flushBlockBytes = 1 shl 17
const maxEndpoint = 500

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

proc buildPrimeFlags(): seq[bool] =
  var primeFlags = newSeq[bool](maxEndpoint + 1)
  var endpoint = 2
  while endpoint <= maxEndpoint:
    primeFlags[endpoint] = true
    endpoint += 1
  var candidate = 2
  while candidate * candidate <= maxEndpoint:
    if primeFlags[candidate]:
      var multiple = candidate * candidate
      while multiple <= maxEndpoint:
        primeFlags[multiple] = false
        multiple += candidate
    candidate += 1
  return primeFlags

let primeFlags = buildPrimeFlags()
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  var leftEndpoint = nextInt(inputData, scanPos)
  var rightEndpoint = nextInt(inputData, scanPos)
  if leftEndpoint > rightEndpoint:
    swap(leftEndpoint, rightEndpoint)
  var lineText = ""
  var hasPreviousPrime = false
  var endpoint = leftEndpoint
  while endpoint <= rightEndpoint:
    if primeFlags[endpoint]:
      if hasPreviousPrime:
        lineText.add ','
      lineText.add $endpoint
      hasPreviousPrime = true
    endpoint += 1
  appendOutput(lineText)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

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
  let elementCount = nextInt(inputData, scanPos)
  var values = newSeq[int](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    values[elementIndex] = nextInt(inputData, scanPos)
  let targetLength = nextInt(inputData, scanPos)
  if targetLength > elementCount:
    appendOutput("-1")
    outputBuffer.add '\n'
    continue
  var tails = newSeq[int](elementCount + 1)
  tails[0] = -1
  var currentLength = 0
  for value in values:
    var lowBound = 0
    var highBound = currentLength
    while lowBound < highBound:
      let middle = (lowBound + highBound + 1) div 2
      if tails[middle] < value:
        lowBound = middle
      else:
        highBound = middle - 1
    let newLength = lowBound + 1
    tails[newLength] = value
    if newLength > currentLength:
      currentLength = newLength
  if currentLength >= targetLength:
    appendOutput($tails[targetLength])
  else:
    appendOutput("-1")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const growthHeadroom = 46

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
  let startingCapital = nextInt(inputData, scanPos)
  let yearCount = nextInt(inputData, scanPos)
  let bondCount = nextInt(inputData, scanPos)
  var bondValues = newSeq[int](bondCount)
  var bondInterests = newSeq[int](bondCount)
  for bondIndex in 0 .. bondCount - 1:
    bondValues[bondIndex] = nextInt(inputData, scanPos) div 1000
    bondInterests[bondIndex] = nextInt(inputData, scanPos)
  let unitCap = (startingCapital div 1000) * growthHeadroom + 100
  var bestInterest = newSeq[int](unitCap + 1)
  for investedUnits in 1 .. unitCap:
    var largestInterest = 0
    for bondIndex in 0 .. bondCount - 1:
      if bondValues[bondIndex] <= investedUnits:
        let candidate = bestInterest[investedUnits - bondValues[bondIndex]] + bondInterests[bondIndex]
        if candidate > largestInterest:
          largestInterest = candidate
    bestInterest[investedUnits] = largestInterest
  var capital = startingCapital
  for yearIndex in 0 .. yearCount - 1:
    let investedUnits = capital div 1000
    if investedUnits <= unitCap:
      capital += bestInterest[investedUnits]
  appendOutput($capital)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

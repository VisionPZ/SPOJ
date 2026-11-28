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

proc stepContribution(stepSize: int, phiTable: seq[int]): int64 =
  if stepSize == 1:
    return 1
  return int64(phiTable[stepSize + 1] div 2)

let targetValue = nextInt(inputData, scanPos)
let sieveLimit = targetValue + 1
var phiValues = newSeq[int](sieveLimit + 1)
for index in 0 .. sieveLimit:
  phiValues[index] = index
for primeCandidate in 2 .. sieveLimit:
  if phiValues[primeCandidate] == primeCandidate:
    var multiple = primeCandidate
    while multiple <= sieveLimit:
      phiValues[multiple] = (phiValues[multiple] div primeCandidate) * (primeCandidate - 1)
      multiple += primeCandidate

var rectangleCount: int64 = 0
var divisor = 1
while divisor * divisor <= targetValue:
  if targetValue mod divisor == 0:
    rectangleCount += stepContribution(divisor, phiValues)
    let pairedDivisor = targetValue div divisor
    if pairedDivisor != divisor:
      rectangleCount += stepContribution(pairedDivisor, phiValues)
  divisor += 1

appendOutput($rectangleCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const maximumDegree = 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var binomial = newSeq[seq[int64]](maximumDegree + 2)
for rowIndex in 0 .. maximumDegree + 1:
  binomial[rowIndex] = newSeq[int64](maximumDegree + 2)
  binomial[rowIndex][0] = 1
  for columnIndex in 1 .. rowIndex:
    binomial[rowIndex][columnIndex] = binomial[rowIndex - 1][columnIndex - 1] +
                                      binomial[rowIndex - 1][columnIndex]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let degree = nextInt(inputData, scanPos)
  var sourceCoefficients = newSeq[int64](degree + 1)
  for coefficientIndex in 0 .. degree:
    sourceCoefficients[coefficientIndex] = int64(nextInt(inputData, scanPos))
  var resultCoefficients = newSeq[int64](degree + 1)
  for sourceDegree in countdown(degree, 0):
    var residual = sourceCoefficients[sourceDegree]
    for higherDegree in sourceDegree + 1 .. degree:
      let sign = if (higherDegree - sourceDegree) mod 2 == 0: int64(1) else: int64(-1)
      residual = residual - sign * binomial[higherDegree + 1][sourceDegree] *
                 resultCoefficients[higherDegree]
    resultCoefficients[sourceDegree] = residual div binomial[sourceDegree + 1][sourceDegree]
  for coefficientIndex in 0 .. degree:
    if coefficientIndex > 0:
      outputBuffer.add ' '
    appendOutput($resultCoefficients[coefficientIndex])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

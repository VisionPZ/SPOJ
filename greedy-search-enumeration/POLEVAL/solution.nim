const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var degree = nextInt(inputData, scanPos)
var caseNumber = 1
while degree != -1:
  var coefficients = newSeq[int64](degree + 1)
  for coefficientIndex in 0 .. degree:
    coefficients[coefficientIndex] = int64(nextInt(inputData, scanPos))
  let pointCount = nextInt(inputData, scanPos)
  appendOutput("Case " & $caseNumber & ":\n")
  for pointIndex in 0 .. pointCount - 1:
    let point = int64(nextInt(inputData, scanPos))
    var evaluated: int64 = 0
    for coefficientIndex in 0 .. degree:
      evaluated = evaluated * point + coefficients[coefficientIndex]
    appendOutput($evaluated)
    outputBuffer.add '\n'
  caseNumber += 1
  degree = nextInt(inputData, scanPos)

stdout.write outputBuffer
outputBuffer.setLen 0

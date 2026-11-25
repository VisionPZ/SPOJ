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
  let termNumber = nextInt(inputData, scanPos)
  var diagonal = 1
  var previousTerms = 0
  while previousTerms + diagonal < termNumber:
    previousTerms += diagonal
    diagonal += 1
  let positionInDiagonal = termNumber - previousTerms
  var numerator = 0
  var denominator = 0
  if (diagonal mod 2) == 0:
    numerator = positionInDiagonal
    denominator = diagonal + 1 - positionInDiagonal
  else:
    numerator = diagonal + 1 - positionInDiagonal
    denominator = positionInDiagonal
  appendOutput("TERMINO " & $termNumber & " ES " & $numerator & "/" & $denominator)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

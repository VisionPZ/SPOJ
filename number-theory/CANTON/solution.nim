const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const searchUpperBound = 10000

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc diagonalForTerm(termIndex: int): int =
  var low = 1
  var high = searchUpperBound
  while low < high:
    let middle = (low + high) div 2
    if (middle * (middle + 1)) div 2 >= termIndex:
      high = middle
    else:
      low = middle + 1
  return low

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

for caseIndex in 0..<caseCount:
  let termIndex = nextInt(inputData, scanPos)
  let diagonalIndex = diagonalForTerm(termIndex)
  let previousTerms = ((diagonalIndex - 1) * diagonalIndex) div 2
  let positionInDiagonal = termIndex - previousTerms - 1
  var numerator = 0
  var denominator = 0
  if diagonalIndex mod 2 == 0:
    numerator = 1 + positionInDiagonal
    denominator = diagonalIndex - positionInDiagonal
  else:
    numerator = diagonalIndex - positionInDiagonal
    denominator = 1 + positionInDiagonal
  outputBuffer.add "TERM "
  outputBuffer.add $termIndex
  outputBuffer.add " IS "
  outputBuffer.add $numerator
  outputBuffer.add "/"
  outputBuffer.add $denominator
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0

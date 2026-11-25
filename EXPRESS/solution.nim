const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and not ((data[pos] >= 'a' and data[pos] <= 'z') or (data[pos] >= 'A' and data[pos] <= 'Z')):
    pos += 1
  var word = ""
  while pos < data.len and ((data[pos] >= 'a' and data[pos] <= 'z') or (data[pos] >= 'A' and data[pos] <= 'Z')):
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let expression = nextWord(inputData, scanPos)
  var leftBound = newSeq[int](expression.len)
  var rightBound = newSeq[int](expression.len)
  var parseStack = newSeq[int](expression.len)
  var parseTop = 0
  for charIndex in 0 .. expression.len - 1:
    if expression[charIndex] >= 'a':
      parseStack[parseTop] = charIndex
      parseTop += 1
    else:
      parseTop -= 1
      let rightStart = parseStack[parseTop]
      parseTop -= 1
      let leftStart = parseStack[parseTop]
      leftBound[charIndex] = leftStart
      rightBound[charIndex] = rightStart
      parseStack[parseTop] = leftStart
      parseTop += 1
  let capacity = 2 * expression.len + 10
  var pendingLeft = newSeq[int](capacity)
  var pendingRight = newSeq[int](capacity)
  var pendingFront = expression.len + 3
  var pendingBack = pendingFront
  pendingLeft[pendingFront] = 0
  pendingRight[pendingFront] = expression.len - 1
  pendingBack += 1
  var recorded = ""
  while pendingBack > pendingFront:
    pendingBack -= 1
    let pieceLeft = pendingLeft[pendingBack]
    let pieceRight = pendingRight[pendingBack]
    if pieceLeft == pieceRight:
      recorded.add expression[pieceLeft]
    else:
      let operatorIndex = pieceRight
      let rightStart = rightBound[operatorIndex]
      pendingFront -= 2
      pendingLeft[pendingFront] = rightStart
      pendingRight[pendingFront] = operatorIndex - 1
      pendingLeft[pendingFront + 1] = leftBound[operatorIndex]
      pendingRight[pendingFront + 1] = rightStart - 1
      recorded.add expression[operatorIndex]
  var rewritten = ""
  for tokenIndex in countdown(recorded.len - 1, 0):
    rewritten.add recorded[tokenIndex]
  appendOutput(rewritten)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

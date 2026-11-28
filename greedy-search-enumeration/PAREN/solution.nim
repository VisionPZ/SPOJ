const flushBlockBytes = 1 shl 17
const maxOperands = 55

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

proc skipLineBreaks(data: string, pos: var int) =
  while pos < data.len and (data[pos] == '\n' or data[pos] == '\r'):
    pos += 1

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\t'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] != ' ' and data[pos] != '\t' and
      data[pos] != '\n' and data[pos] != '\r':
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var trueWays = newSeq[int64](maxOperands * maxOperands)
var falseWays = newSeq[int64](maxOperands * maxOperands)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  skipLineBreaks(inputData, scanPos)
  var operandValues = newSeq[int](0)
  var operatorKinds = newSeq[int](0)
  while scanPos < inputData.len and inputData[scanPos] != '\n' and
      inputData[scanPos] != '\r':
    let word = nextWord(inputData, scanPos)
    if word.len == 0:
      break
    let initial = word[0]
    if initial == 'T' or initial == 't':
      operandValues.add 1
    elif initial == 'F' or initial == 'f':
      operandValues.add 0
    elif initial == 'a':
      operatorKinds.add 0
    elif initial == 'o':
      operatorKinds.add 1
    else:
      operatorKinds.add 2
  let operandCount = operandValues.len
  if operandCount == 1:
    appendOutput($(int64(operandValues[0])))
    outputBuffer.add '\n'
    continue
  for operandIndex in 0 .. operandCount - 1:
    let cellIndex = operandIndex * maxOperands + operandIndex
    trueWays[cellIndex] = int64(operandValues[operandIndex])
    falseWays[cellIndex] = 1 - int64(operandValues[operandIndex])
  for spanLength in 2 .. operandCount:
    for leftIndex in 0 .. operandCount - spanLength:
      let rightIndex = leftIndex + spanLength - 1
      let cellIndex = leftIndex * maxOperands + rightIndex
      trueWays[cellIndex] = 0
      falseWays[cellIndex] = 0
      for splitIndex in leftIndex .. rightIndex - 1:
        let leftCell = leftIndex * maxOperands + splitIndex
        let rightCell = (splitIndex + 1) * maxOperands + rightIndex
        let leftTrue = trueWays[leftCell]
        let leftFalse = falseWays[leftCell]
        let rightTrue = trueWays[rightCell]
        let rightFalse = falseWays[rightCell]
        case operatorKinds[splitIndex]:
          of 0:
            trueWays[cellIndex] += leftTrue * rightTrue
            falseWays[cellIndex] += (leftTrue + leftFalse) * (rightTrue + rightFalse) -
              leftTrue * rightTrue
          of 1:
            falseWays[cellIndex] += leftFalse * rightFalse
            trueWays[cellIndex] += (leftTrue + leftFalse) * (rightTrue + rightFalse) -
              leftFalse * rightFalse
          else:
            trueWays[cellIndex] += leftTrue * rightFalse + leftFalse * rightTrue
            falseWays[cellIndex] += leftTrue * rightTrue + leftFalse * rightFalse
  appendOutput($(trueWays[operandCount - 1]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

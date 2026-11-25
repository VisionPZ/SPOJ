const flushBlockBytes = 1 shl 17
const limbBase: uint64 = 1000000000'u64

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

var answerLimbs: array[6, uint32]
var answerLength = 0

proc addChunkProduct(primaryValue: uint64, multiplierValue: uint64) =
  var remainingValue = primaryValue
  var carryValue: uint64 = 0
  var limbIndex = 0
  while remainingValue > 0'u64 or carryValue > 0'u64:
    if limbIndex >= answerLength:
      answerLength = limbIndex + 1
      answerLimbs[limbIndex] = 0
    let digitValue = remainingValue mod limbBase
    let productValue = uint64(answerLimbs[limbIndex]) + digitValue * multiplierValue + carryValue
    answerLimbs[limbIndex] = uint32(productValue mod limbBase)
    carryValue = productValue div limbBase
    remainingValue = remainingValue div limbBase
    limbIndex += 1

proc appendBigAnswer() =
  if answerLength == 0:
    appendOutput("0")
    outputBuffer.add '\n'
    return
  var topIndex = answerLength - 1
  appendOutput($answerLimbs[topIndex])
  topIndex -= 1
  while topIndex >= 0:
    var limbText = $answerLimbs[topIndex]
    while limbText.len < 9:
      limbText = "0" & limbText
    appendOutput(limbText)
    topIndex -= 1
  outputBuffer.add '\n'

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let queryValue = int64(nextInt(inputData, scanPos))
  answerLength = 0
  var leftValue: int64 = 1
  while leftValue <= queryValue:
    let quotientValue = queryValue div leftValue
    if quotientValue > 1:
      let rightValue = queryValue div quotientValue
      let countValue = rightValue - leftValue + 1
      let pairSum = leftValue + rightValue
      var firstFactor: int64
      var secondFactor: int64
      if (pairSum and 1'i64) == 0'i64:
        firstFactor = pairSum div 2
        secondFactor = countValue
      else:
        firstFactor = pairSum
        secondFactor = countValue div 2
      addChunkProduct(uint64(firstFactor) * uint64(secondFactor), uint64(quotientValue - 1))
      leftValue = rightValue + 1
    else:
      leftValue = queryValue + 1
  appendBigAnswer()
stdout.write outputBuffer
outputBuffer.setLen 0

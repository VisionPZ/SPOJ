const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const unvisitedMarker = -2

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value

proc smallestBinaryMultiple(divisor: int): string =
  if divisor == 1:
    return "1"
  var parentRemainder = newSeq[int](divisor)
  var parentDigit = newSeq[char](divisor)
  var bfsQueue = newSeq[int](divisor)
  for remainder in 0 ..< divisor:
    parentRemainder[remainder] = unvisitedMarker
  var queueHead = 0
  var queueTail = 0
  var startRemainder = 1 mod divisor
  parentRemainder[startRemainder] = -1
  parentDigit[startRemainder] = '1'
  bfsQueue[queueTail] = startRemainder
  queueTail += 1
  var foundRemainder = -1
  while foundRemainder < 0 and queueHead < queueTail:
    let currentRemainder = bfsQueue[queueHead]
    queueHead += 1
    var digitValue = 0
    while digitValue <= 1:
      let nextRemainder = (currentRemainder * 10 + digitValue) mod divisor
      if parentRemainder[nextRemainder] == unvisitedMarker:
        parentRemainder[nextRemainder] = currentRemainder
        if digitValue == 0:
          parentDigit[nextRemainder] = '0'
        else:
          parentDigit[nextRemainder] = '1'
        if nextRemainder == 0:
          foundRemainder = 0
          break
        bfsQueue[queueTail] = nextRemainder
        queueTail += 1
      digitValue += 1
  var digitCount = 0
  var traceRemainder = foundRemainder
  while traceRemainder >= 0:
    digitCount += 1
    traceRemainder = parentRemainder[traceRemainder]
  var answer = newString(digitCount)
  var writePos = digitCount - 1
  traceRemainder = foundRemainder
  while traceRemainder >= 0:
    answer[writePos] = parentDigit[traceRemainder]
    writePos -= 1
    traceRemainder = parentRemainder[traceRemainder]
  return answer

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var cachedAnswers = newSeq[string](20001)
var outputBuffer = ""
for _ in 1 .. caseCount:
  let divisor = nextInt(inputData, scanPos)
  if cachedAnswers[divisor].len == 0:
    cachedAnswers[divisor] = smallestBinaryMultiple(divisor)
  outputBuffer.add cachedAnswers[divisor]
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer

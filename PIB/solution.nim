import math

const flushBlockBytes = 1 shl 17
const limbBase = int64(1000000000)
const piValue = 3.14159265358979323846

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

proc trimNumber(value: var seq[int32]) =
  while value.len > 0 and value[value.len - 1] == 0:
    value.setLen(value.len - 1)

proc addNumber(target: var seq[int32], source: seq[int32]) =
  let maxLength = max(target.len, source.len)
  target.setLen(maxLength)
  var carry: int64 = 0
  for index in 0 .. maxLength - 1:
    var limbTotal = carry
    if index < target.len:
      limbTotal += int64(target[index])
    if index < source.len:
      limbTotal += int64(source[index])
    target[index] = int32(limbTotal mod limbBase)
    carry = limbTotal div limbBase
  if carry > 0:
    target.add int32(carry)

proc multiplyNumber(value: var seq[int32], factor: int64) =
  var carry: int64 = 0
  for index in 0 .. value.len - 1:
    let product = int64(value[index]) * factor + carry
    value[index] = int32(product mod limbBase)
    carry = product div limbBase
  while carry > 0:
    value.add int32(carry mod limbBase)
    carry = carry div limbBase

proc divideNumber(value: var seq[int32], divisor: int64) =
  var remainder: int64 = 0
  var index = value.len - 1
  while index >= 0:
    let current = remainder * limbBase + int64(value[index])
    value[index] = int32(current div divisor)
    remainder = current mod divisor
    index -= 1
  trimNumber(value)

proc numberToText(value: seq[int32]): string =
  if value.len == 0:
    return "0"
  result = $value[value.len - 1]
  var index = value.len - 2
  while index >= 0:
    var chunk = $value[index]
    while chunk.len < 9:
      chunk = "0" & chunk
    result.add chunk
    index -= 1

proc solveQuery(query: int): string =
  if query < 4:
    return "1"
  let threshold = query - 4
  var total = newSeq[int32](0)
  var currentN = threshold
  var currentK = threshold
  var binomial = newSeq[int32](1)
  binomial[0] = 1
  var firstTerm = true
  var stepCount = 0
  while true:
    let baseValue = float(threshold) - float(stepCount) * piValue
    let highestP = int(floor(baseValue + 1e-9))
    if highestP < 0:
      break
    let lowestFirst = int(floor(baseValue - piValue + 1e-9)) + 1
    let lowestSecond = int(floor(baseValue - 1.0 + 1e-9)) + 1
    var keptP = highestP
    while keptP >= max(0, lowestFirst):
      let wantedN = keptP + stepCount
      let wantedK = keptP
      if firstTerm:
        currentN = wantedN
        currentK = wantedK
        firstTerm = false
      else:
        while currentK > wantedK:
          multiplyNumber(binomial, int64(currentK))
          divideNumber(binomial, int64(currentN - currentK + 1))
          currentK -= 1
        while currentN > wantedN:
          multiplyNumber(binomial, int64(currentN - currentK))
          divideNumber(binomial, int64(currentN))
          currentN -= 1
      addNumber(total, binomial)
      if keptP >= lowestSecond:
        addNumber(total, binomial)
      keptP -= 1
    stepCount += 1
  return numberToText(total)

while true:
  let query = nextInt(inputData, scanPos)
  if query < 0:
    break
  let answerText = solveQuery(query)
  var digitPos = 0
  while digitPos < answerText.len:
    let chunkLength = min(50, answerText.len - digitPos)
    appendOutput(answerText.substr(digitPos, digitPos + chunkLength - 1))
    outputBuffer.add '\n'
    digitPos += chunkLength
stdout.write outputBuffer
outputBuffer.setLen 0

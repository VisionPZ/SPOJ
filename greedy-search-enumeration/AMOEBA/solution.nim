const flushBlockBytes = 1 shl 17
const digitBase = 10
const growthFactor = 7'i64
const maxDigitCount = 9

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc powerMod(baseValue, exponentValue, modulus: int64): int64 =
  var answer: int64 = 1 mod modulus
  var factor = baseValue mod modulus
  var remaining = exponentValue
  while remaining > 0:
    if (remaining and 1) == 1:
      answer = (answer * factor) mod modulus
    factor = (factor * factor) mod modulus
    remaining = remaining shr 1
  return answer

proc findEarliestDay(targetValue: int64, digitCount: int): int64 =
  var modulus: int64 = 10
  var exponent: int64 = -1
  var currentPower: int64 = 1
  for step in 0 .. 3:
    if currentPower == targetValue mod modulus:
      exponent = int64(step)
      break
    currentPower = (currentPower * growthFactor) mod modulus
  if exponent < 0:
    return -1
  var period: int64 = 4
  for digitIndex in 2 .. digitCount:
    modulus = modulus * digitBase
    let wanted = targetValue mod modulus
    let stepFactor = powerMod(growthFactor, period, modulus)
    var candidatePower = powerMod(growthFactor, exponent, modulus)
    var found = false
    var shift: int64 = 0
    var factorPower: int64 = 1
    while true:
      if candidatePower == wanted:
        exponent += shift * period
        found = true
        break
      shift += 1
      factorPower = (factorPower * stepFactor) mod modulus
      if factorPower == 1:
        break
      candidatePower = (candidatePower * stepFactor) mod modulus
    if not found:
      return -1
    var orderFactor: int64 = 1
    var checkPower = stepFactor
    while checkPower != 1:
      checkPower = (checkPower * stepFactor) mod modulus
      orderFactor += 1
    period = period * orderFactor
  return exponent + 1

while true:
  let queryToken = nextToken(inputData, scanPos)
  if queryToken.len == 0:
    break
  if queryToken.len < 1 or queryToken.len > maxDigitCount:
    continue
  var targetValue: int64 = 0
  for charIndex in 0 .. queryToken.len - 1:
    targetValue = targetValue * digitBase + int64(int(queryToken[charIndex]) - 48)
  let answerDay = findEarliestDay(targetValue, queryToken.len)
  appendOutput($answerDay)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

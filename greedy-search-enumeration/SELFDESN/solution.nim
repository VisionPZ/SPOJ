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

proc powerMod(baseValue: int64, exponentValue: int64, modulus: int64): int64 =
  var powerResult: int64 = 1 mod modulus
  var factor = baseValue mod modulus
  var remaining = exponentValue
  while remaining > 0:
    if (remaining and 1) == 1:
      powerResult = (powerResult * factor) mod modulus
    factor = (factor * factor) mod modulus
    remaining = remaining div 2
  return powerResult

proc selfValueMod(indexValue: int64, modulus: int64): int64 =
  if indexValue == 1:
    return 100 mod modulus
  if indexValue == 2:
    return 136 mod modulus
  if indexValue == 3:
    return 1425 mod modulus
  let baseValue = indexValue + 3
  let reducedBase = baseValue mod modulus
  let leadingExponent = baseValue - 1
  let leadingPower = powerMod(reducedBase, leadingExponent, modulus)
  let secondPower = powerMod(reducedBase, leadingExponent - 1, modulus)
  let thirdPower = powerMod(reducedBase, leadingExponent - 2, modulus)
  let cubePower = powerMod(reducedBase, 3, modulus)
  let leadingDigit = (reducedBase - 4 + modulus) mod modulus
  let total = (leadingDigit * leadingPower + 2 * secondPower + thirdPower + cubePower) mod modulus
  return total

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let indexValue = int64(nextInt(inputData, scanPos))
  let modulus = int64(nextInt(inputData, scanPos))
  appendOutput($selfValueMod(indexValue, modulus))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

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

proc multiplyMatrices(first: array[4, int64], second: array[4, int64], modulus: int64): array[4, int64] =
  result[0] = (first[0] * second[0] + first[1] * second[2]) mod modulus
  result[1] = (first[0] * second[1] + first[1] * second[3]) mod modulus
  result[2] = (first[2] * second[0] + first[3] * second[2]) mod modulus
  result[3] = (first[2] * second[1] + first[3] * second[3]) mod modulus

proc matrixPower(base: array[4, int64], exponentValue: int64, modulus: int64): array[4, int64] =
  result = [1'i64, 0'i64, 0'i64, 1'i64]
  var factor = base
  var remaining = exponentValue
  while remaining > 0:
    if (remaining and 1) == 1:
      result = multiplyMatrices(result, factor, modulus)
    factor = multiplyMatrices(factor, factor, modulus)
    remaining = remaining div 2

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rank = int64(nextInt(inputData, scanPos))
  let modulus = int64(nextInt(inputData, scanPos))
  let doubledModulus = 2 * modulus
  let base = [3'i64, 4'i64, 2'i64, 3'i64]
  let powered = matrixPower(base, rank - 1, doubledModulus)
  let oddTerm = (powered[0] * 7'i64 + powered[1] * 5'i64) mod doubledModulus
  let hypotenuse = (powered[2] * 7'i64 + powered[3] * 5'i64) mod doubledModulus
  let leg = ((oddTerm - 1) div 2) mod modulus
  appendOutput($leg)
  outputBuffer.add ' '
  appendOutput($(hypotenuse mod modulus))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

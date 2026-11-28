const flushBlockBytes = 1 shl 17
const firstDigitCode = 48
const firstUpperCode = 55

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitCode)
    pos += 1
  return value

proc isSuffixCharacter(character: char): bool =
  return (character >= '0' and character <= '9') or (character >= 'A' and character <= 'Z')

proc nextSuffixToken(data: string, pos: var int): string =
  while pos < data.len and not isSuffixCharacter(data[pos]):
    pos += 1
  var token = ""
  while pos < data.len and isSuffixCharacter(data[pos]):
    token.add data[pos]
    pos += 1
  return token

proc digitValue(character: char): int64 =
  if character >= '0' and character <= '9':
    return int64(int(character) - firstDigitCode)
  return int64(int(character) - firstUpperCode)

proc extendedGcd(firstValue: int64, secondValue: int64, coefficient: var int64,
                 otherCoefficient: var int64): int64 =
  if secondValue == 0:
    coefficient = 1
    otherCoefficient = 0
    return firstValue
  var innerCoefficient: int64 = 0
  var innerOther: int64 = 0
  let common = extendedGcd(secondValue, firstValue mod secondValue,
                           innerCoefficient, innerOther)
  coefficient = innerOther
  otherCoefficient = innerCoefficient - (firstValue div secondValue) * innerOther
  return common

proc multiplyModulo(leftFactor: int64, rightFactor: int64, modulus: int64): int64 =
  var product: int64 = 0
  var doubledFactor = leftFactor mod modulus
  var multiplier = rightFactor mod modulus
  while multiplier > 0:
    if (multiplier and 1) == 1:
      product = (product + doubledFactor) mod modulus
    doubledFactor = (doubledFactor * 2) mod modulus
    multiplier = multiplier shr 1
  return product

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let constraintCount = int(nextInt(inputData, scanPos))
var resultResidue: int64 = 0
var resultModulus: int64 = 1

for constraintIndex in 0 .. constraintCount - 1:
  let baseValue = nextInt(inputData, scanPos)
  let suffixText = nextSuffixToken(inputData, scanPos)
  var suffixValue: int64 = 0
  var modulusPower: int64 = 1
  for letter in suffixText:
    suffixValue = suffixValue * baseValue + digitValue(letter)
    modulusPower = modulusPower * baseValue

  var unusedCoefficient: int64 = 0
  var unusedOther: int64 = 0
  let commonDivisor = extendedGcd(resultModulus, modulusPower,
                                  unusedCoefficient, unusedOther)
  let reducedModulus = modulusPower div commonDivisor
  var stepValue: int64 = 0
  if reducedModulus > 1:
    let difference = (suffixValue - resultResidue) div commonDivisor
    var differenceModulo = difference mod reducedModulus
    if differenceModulo < 0:
      differenceModulo += reducedModulus
    var inverseCoefficient: int64 = 0
    var inverseOther: int64 = 0
    discard extendedGcd(resultModulus div commonDivisor, reducedModulus,
                        inverseCoefficient, inverseOther)
    var inverseValue = inverseCoefficient mod reducedModulus
    if inverseValue < 0:
      inverseValue += reducedModulus
    stepValue = multiplyModulo(differenceModulo, inverseValue, reducedModulus)

  let combinedModulus = resultModulus * reducedModulus
  var candidate = (resultResidue + resultModulus * stepValue) mod combinedModulus
  if candidate < 0:
    candidate += combinedModulus
  resultResidue = candidate
  resultModulus = combinedModulus

appendOutput($resultResidue)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

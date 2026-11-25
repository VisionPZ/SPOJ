const flushBlockBytes = 1 shl 17

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
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc powerMod(baseValue, exponentValue, modulusValue: uint64): uint64 =
  var resultValue: uint64 = 1
  var baseReduced = baseValue mod modulusValue
  var exponentLeft = exponentValue
  while exponentLeft > 0'u64:
    if (exponentLeft and 1'u64) != 0'u64:
      resultValue = (resultValue * baseReduced) mod modulusValue
    baseReduced = (baseReduced * baseReduced) mod modulusValue
    exponentLeft = exponentLeft shr 1
  return resultValue

proc isPrime(number: uint64): bool =
  if number < 2'u64:
    return false
  const smallPrimes = [2'u64, 3'u64, 5'u64, 7'u64, 11'u64, 13'u64,
                       17'u64, 19'u64, 23'u64, 29'u64, 31'u64, 37'u64]
  for primeValue in smallPrimes:
    if number mod primeValue == 0'u64:
      return number == primeValue
  var oddPart = number - 1'u64
  var trailingZeros = 0
  while (oddPart and 1'u64) == 0'u64:
    oddPart = oddPart shr 1
    trailingZeros += 1
  const testBases = [2'u64, 3'u64, 5'u64, 7'u64]
  for baseValue in testBases:
    var probe = powerMod(baseValue, oddPart, number)
    if probe == 1'u64 or probe == number - 1'u64:
      continue
    var passed = false
    for roundIndex in 1 .. trailingZeros - 1:
      probe = (probe * probe) mod number
      if probe == number - 1'u64:
        passed = true
        break
    if not passed:
      return false
  return true

let caseCount = int(nextInt(inputData, scanPos))
for caseIndex in 0 .. caseCount - 1:
  let candidate = uint64(nextInt(inputData, scanPos))
  if isPrime(candidate):
    appendOutput("YES\n")
  else:
    appendOutput("NO\n")
stdout.write outputBuffer
outputBuffer.setLen 0

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

proc powerMod(baseValue, exponentValue, modulusValue: int64): int64 =
  var powerResult = 1.int64
  var currentBase = baseValue mod modulusValue
  var currentExponent = exponentValue
  while currentExponent > 0:
    if (currentExponent and 1) == 1:
      powerResult = powerResult * currentBase mod modulusValue
    currentBase = currentBase * currentBase mod modulusValue
    currentExponent = currentExponent div 2
  return powerResult

proc stripPrime(value, primeValue: int): tuple[exponentCount: int, unitPart: int64] =
  var remaining = value
  var exponentCount = 0
  while remaining mod primeValue == 0:
    remaining = remaining div primeValue
    exponentCount += 1
  return (exponentCount, int64(remaining))

proc factorialUnit(limitValue, primeValue: int, modulusValue: int64): tuple[exponentCount: int, unitPart: int64] =
  var exponentCount = 0
  var unitPart = 1.int64
  for numberValue in 1 .. limitValue:
    var reduced = numberValue
    while reduced mod primeValue == 0:
      reduced = reduced div primeValue
      exponentCount += 1
    unitPart = unitPart * int64(reduced) mod modulusValue
  return (exponentCount, unitPart)

proc catalanModulo(residue, primeValue: int, modulusValue: int64): int64 =
  let doubled = factorialUnit(2 * residue, primeValue, modulusValue)
  let single = factorialUnit(residue, primeValue, modulusValue)
  let divisor = stripPrime(residue + 1, primeValue)
  let eulerExponent = int64(primeValue * (primeValue - 1) - 1)
  let denominatorUnit = powerMod(int64(divisor.unitPart), eulerExponent, modulusValue)
  let squaredUnit = single.unitPart * single.unitPart mod modulusValue
  let denominatorSquare = powerMod(squaredUnit, eulerExponent, modulusValue)
  let netExponent = doubled.exponentCount - 2 * single.exponentCount - divisor.exponentCount
  var answer = powerMod(int64(primeValue), netExponent, modulusValue)
  answer = answer * doubled.unitPart mod modulusValue
  answer = answer * denominatorSquare mod modulusValue
  answer = answer * denominatorUnit mod modulusValue
  return answer

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let residue = nextInt(inputData, scanPos)
  let primeValue = nextInt(inputData, scanPos)
  let exponentValue = nextInt(inputData, scanPos)
  let modulusValue = int64(primeValue) * int64(primeValue)
  var answer: int64
  if (exponentValue and 1) == 1:
    answer = catalanModulo(residue, primeValue, modulusValue)
  else:
    let eulerExponent = int64(primeValue * (primeValue - 1) - 1)
    let fourPower = powerMod(4, int64(residue), modulusValue)
    let twoPower = powerMod(2, int64(primeValue), modulusValue)
    var difference = 2 - twoPower
    difference = difference mod modulusValue
    if difference < 0:
      difference += modulusValue
    answer = fourPower * difference mod modulusValue
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

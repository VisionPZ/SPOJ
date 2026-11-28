const flushBlockBytes = 1 shl 17

{.emit: """
typedef __int128 wide_value;
static const long long powerCoefficients[11][11] = {
  {0,0,0,0,0,0,0,0,0,0,0},
  {13860,13860,0,0,0,0,0,0,0,0,0},
  {4620,13860,9240,0,0,0,0,0,0,0,0},
  {0,6930,13860,6930,0,0,0,0,0,0,0},
  {-924,0,9240,13860,5544,0,0,0,0,0,0},
  {0,-2310,0,11550,13860,4620,0,0,0,0,0},
  {660,0,-4620,0,13860,13860,3960,0,0,0,0},
  {0,2310,0,-8085,0,16170,13860,3465,0,0,0},
  {-924,0,6160,0,-12936,0,18480,13860,3080,0,0},
  {0,-4158,0,13860,0,-19404,0,20790,13860,2772,0},
  {2100,0,-13860,0,27720,0,-27720,0,23100,13860,2520}
};
static NU64 wide_power_sum(NU64 limitValue, unsigned int powerValue, NU64 modulusValue) {
  wide_value reducedModulus = (wide_value)modulusValue * 27720;
  wide_value accumulated = 0;
  int degree = (int)powerValue + 1;
  int idx = degree;
  while (idx >= 1) {
    accumulated = (accumulated * (wide_value)limitValue + (wide_value)powerCoefficients[powerValue][idx - 1]) % reducedModulus;
    idx -= 1;
  }
  accumulated = (accumulated * (wide_value)limitValue) % reducedModulus;
  return (NU64)(accumulated / 27720);
}
static NU64 wide_multiply_mod(NU64 firstValue, NU64 secondValue, NU64 modulusValue) {
  return (NU64)((__int128)firstValue * secondValue % modulusValue);
}
""".}

proc powerSumModulo(limitValue: uint64, powerValue: cuint, modulusValue: uint64): uint64 {.importc: "wide_power_sum", cdecl.}
proc multiplyModulo(firstValue: uint64, secondValue: uint64, modulusValue: uint64): uint64 {.importc: "wide_multiply_mod", cdecl.}

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

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let queryValue = uint64(nextInt(inputData, scanPos))
  let powerValue = cuint(nextInt(inputData, scanPos))
  let modulusValue = uint64(nextInt(inputData, scanPos))
  var answerValue: uint64 = 0
  var previousPowerSum: uint64 = 0
  var leftValue: uint64 = 1
  while leftValue <= queryValue:
    let quotientValue = queryValue div leftValue
    let rightValue = queryValue div quotientValue
    let currentPowerSum = powerSumModulo(rightValue, powerValue, modulusValue)
    let rangeSum = (currentPowerSum - previousPowerSum + modulusValue) mod modulusValue
    let chunkProduct = multiplyModulo(rangeSum, quotientValue mod modulusValue, modulusValue)
    answerValue = (answerValue + chunkProduct) mod modulusValue
    previousPowerSum = currentPowerSum
    leftValue = rightValue + 1
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

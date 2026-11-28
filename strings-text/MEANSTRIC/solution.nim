{.passL: "-lm".}

const flushBlockBytes = 1 shl 17
const lineBufferSize = 128
const decimalTarget = 9
const decimalUnit = 1000000000

{.emit: "#include <math.h>\n#include <stdlib.h>\n".}

{.emit: """
static long double meanAdd(long double leftValue, long double rightValue) {
  return leftValue + rightValue;
}
static long double meanDivide(long double leftValue, long double rightValue) {
  return leftValue / rightValue;
}
static long double meanLog(long double value) {
  return logl(value);
}
static long double meanExp(long double value) {
  return expl(value);
}
static long double meanParse(char* text, char** endPtr) {
  return strtold(text, endPtr);
}
static int meanFormatValue(char* buffer, int bufferSize, long double value) {
  return snprintf(buffer, (size_t)bufferSize, "%.9Lf", value);
}
""".}

proc c_parseFloat(text: cstring, endPtr: ptr cstring): clongdouble {.importc: "meanParse", cdecl.}
proc c_add(leftValue: clongdouble, rightValue: clongdouble): clongdouble {.importc: "meanAdd", cdecl.}
proc c_divide(leftValue: clongdouble, rightValue: clongdouble): clongdouble {.importc: "meanDivide", cdecl.}
proc c_log(value: clongdouble): clongdouble {.importc: "meanLog", cdecl.}
proc c_exp(value: clongdouble): clongdouble {.importc: "meanExp", cdecl.}
proc c_formatValue(buffer: cstring, bufferSize: cint, value: clongdouble): cint {.importc: "meanFormatValue", cdecl.}

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
inputData.add '\0'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc nextFloat(data: string, pos: var int): clongdouble =
  let startAddress = cast[cstring](unsafeAddr data[pos])
  var endAddress: cstring = nil
  result = c_parseFloat(startAddress, addr endAddress)
  pos = pos + int(cast[uint](endAddress) - cast[uint](startAddress))

proc parseScaledToken(data: string, pos: var int, mantissa: var int64, effectiveDecimals: var int) =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  mantissa = 0
  var fractionalDigits = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    mantissa = mantissa * 10 + int64(int(data[pos]) - 48)
    pos += 1
  if pos < data.len and data[pos] == '.':
    pos += 1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      mantissa = mantissa * 10 + int64(int(data[pos]) - 48)
      fractionalDigits += 1
      pos += 1
  var exponentValue = 0
  if pos < data.len and (data[pos] == 'e' or data[pos] == 'E'):
    pos += 1
    var exponentNegative = false
    if pos < data.len and data[pos] == '-':
      exponentNegative = true
      pos += 1
    elif pos < data.len and data[pos] == '+':
      pos += 1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      exponentValue = exponentValue * 10 + int(data[pos]) - 48
      pos += 1
    if exponentNegative:
      exponentValue = -exponentValue
  effectiveDecimals = fractionalDigits - exponentValue

proc powerOfTen(exponent: int): int64 =
  result = 1
  for step in 0 .. exponent - 1:
    result = result * 10

proc formatExactArithmetic(sumScaled: int64, numberCount: int, decimalPlaces: int): string =
  var numerator: int64 = 0
  var denominator: int64 = 0
  if decimalPlaces <= decimalTarget:
    numerator = sumScaled * powerOfTen(decimalTarget - decimalPlaces)
    denominator = int64(numberCount)
  else:
    numerator = sumScaled
    denominator = int64(numberCount) * powerOfTen(decimalPlaces - decimalTarget)
  var scaledResult = numerator div denominator
  let remainder = numerator mod denominator
  let doubledRemainder = remainder * 2
  if doubledRemainder > denominator or (doubledRemainder == denominator and scaledResult mod 2 == 1):
    scaledResult += 1
  let wholePart = scaledResult div int64(decimalUnit)
  let fractionPart = scaledResult mod int64(decimalUnit)
  var fractionText = $fractionPart
  while fractionText.len < decimalTarget:
    fractionText = "0" & fractionText
  return $wholePart & "." & fractionText

proc formatLongDouble(value: clongdouble): string =
  var valueBuffer: array[lineBufferSize, char]
  discard c_formatValue(cast[cstring](addr valueBuffer[0]), cint(lineBufferSize), value)
  return $cast[cstring](addr valueBuffer[0])

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let numberCount = nextInt(inputData, scanPos)
  let caseStartPos = scanPos
  var tokenMantissas = newSeq[int64](numberCount)
  var tokenDecimals = newSeq[int](numberCount)
  var maxDecimals = 0
  for valueIndex in 0 .. numberCount - 1:
    parseScaledToken(inputData, scanPos, tokenMantissas[valueIndex], tokenDecimals[valueIndex])
    if tokenDecimals[valueIndex] > maxDecimals:
      maxDecimals = tokenDecimals[valueIndex]
  var sumScaled: int64 = 0
  for valueIndex in 0 .. numberCount - 1:
    sumScaled = sumScaled + tokenMantissas[valueIndex] * powerOfTen(maxDecimals - tokenDecimals[valueIndex])
  let arithmeticText = formatExactArithmetic(sumScaled, numberCount, maxDecimals)
  scanPos = caseStartPos
  var sumLogs: clongdouble = 0
  var sumReciprocals: clongdouble = 0
  for valueIndex in 0 .. numberCount - 1:
    let currentValue = nextFloat(inputData, scanPos)
    sumLogs = c_add(sumLogs, c_log(currentValue))
    sumReciprocals = c_add(sumReciprocals, c_divide(clongdouble(1), currentValue))
  let count: clongdouble = clongdouble(numberCount)
  let geometricMean: clongdouble = c_exp(c_divide(sumLogs, count))
  let harmonicMean: clongdouble = c_divide(count, sumReciprocals)
  appendOutput(arithmeticText & " " & formatLongDouble(geometricMean) & " " & formatLongDouble(harmonicMean) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0

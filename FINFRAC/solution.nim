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

proc simplestFraction(lowNumerator: int64, lowDenominator: int64,
                      highNumerator: int64, highDenominator: int64): (int64, int64) =
  let lowWhole = lowNumerator div lowDenominator
  let lowRest = lowNumerator mod lowDenominator
  let highWhole = highNumerator div highDenominator
  let highRest = highNumerator mod highDenominator
  if lowWhole + 1 < highWhole:
    return (lowWhole + 1, 1'i64)
  if lowWhole == highWhole:
    if lowRest == 0:
      let chosenDenominator = highDenominator div highRest + 1
      return (lowWhole * chosenDenominator + 1, chosenDenominator)
    let inner = simplestFraction(highDenominator, highRest, lowDenominator, lowRest)
    return (lowWhole * inner[0] + inner[1], inner[0])
  if highRest > 0:
    return (lowWhole + 1, 1'i64)
  if lowRest == 0:
    return (2 * lowWhole + 1, 2'i64)
  let inner = simplestFraction(1, 1, lowDenominator, lowRest)
  return (lowWhole * inner[0] + inner[1], inner[0])

while true:
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  if scanPos >= inputData.len:
    break
  let lowNumerator = int64(nextInt(inputData, scanPos))
  let lowDenominator = int64(nextInt(inputData, scanPos))
  let highNumerator = int64(nextInt(inputData, scanPos))
  let highDenominator = int64(nextInt(inputData, scanPos))
  let answer = simplestFraction(lowNumerator, lowDenominator, highNumerator, highDenominator)
  appendOutput($answer[0] & "/" & $answer[1] & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0

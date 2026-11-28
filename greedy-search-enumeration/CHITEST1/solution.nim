import strutils

const flushBlockBytes = 1 shl 17

proc nextNumber(inputData: string, pos: var int): float =
  while pos < inputData.len and (inputData[pos] < '0' or inputData[pos] > '9') and
        inputData[pos] != '-' and inputData[pos] != '.':
    pos += 1
  var signValue = 1.0
  if pos < inputData.len and inputData[pos] == '-':
    signValue = -1.0
    pos += 1
  var wholePart = 0.0
  while pos < inputData.len and inputData[pos] >= '0' and inputData[pos] <= '9':
    wholePart = wholePart * 10.0 + float(int(inputData[pos]) - 48)
    pos += 1
  var fractionPart = 0.0
  var scale = 1.0
  if pos < inputData.len and inputData[pos] == '.':
    pos += 1
    while pos < inputData.len and inputData[pos] >= '0' and inputData[pos] <= '9':
      scale = scale * 10.0
      fractionPart = fractionPart + float(int(inputData[pos]) - 48) / scale
      pos += 1
  return signValue * (wholePart + fractionPart)

proc formatSum(value: float): string =
  result = formatFloat(value, ffDecimal, 6)
  while result.len > 0 and result[result.len - 1] == '0':
    result.setLen result.len - 1
  if result.len > 0 and result[result.len - 1] == '.':
    result.setLen result.len - 1

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var pos = 0
let caseCount = int(nextNumber(inputData, pos))
var outputBuffer = ""
for _ in 0 ..< caseCount:
  let firstNumber = nextNumber(inputData, pos)
  let secondNumber = nextNumber(inputData, pos)
  outputBuffer.add formatSum(firstNumber + secondNumber)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer

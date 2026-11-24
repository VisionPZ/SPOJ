const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

proc skipSpace(data: string, position: var int) =
  while position < data.len and (data[position] == ' ' or data[position] == '\n' or
      data[position] == '\r' or data[position] == '\t'):
    position += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let weightCount = nextInt(inputData, scanPos)
  let bitLength = nextInt(inputData, scanPos)
  let modulus = nextInt(inputData, scanPos)
  skipSpace(inputData, scanPos)
  var countZero = 1 mod modulus
  var countOne = 0
  for i in 0..<bitLength:
    let j = scanPos + bitLength - 1 - i
    if inputData[j] == '1':
      countOne = (countZero + countOne) mod modulus
    else:
      countZero = (countZero + countOne) mod modulus
  scanPos += bitLength
  countZero = (countZero + (weightCount - bitLength) * countOne) mod modulus
  appendOutput($countZero)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

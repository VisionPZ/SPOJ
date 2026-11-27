const flushBlockBytes = 1 shl 17
const maxVaults = 10

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

proc nextDigitSum(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var digitSum: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    digitSum += int64(int(data[pos]) - 48)
    pos += 1
  return digitSum

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var coeffA: array[maxVaults, int64]
var coeffB: array[maxVaults, int64]

while scanPos < inputData.len:
  let vaultCount = nextInt(inputData, scanPos)
  let startVault = nextInt(inputData, scanPos)
  let stepCount = nextInt(inputData, scanPos)
  if vaultCount == 0 and startVault == 0 and stepCount == 0:
    break
  for idx in 0 .. vaultCount - 1:
    coeffA[idx] = int64(nextInt(inputData, scanPos))
    coeffB[idx] = int64(nextInt(inputData, scanPos))
  var currentValue = nextDigitSum(inputData, scanPos)
  var currentVault = int(currentValue mod int64(vaultCount))
  for step in 0 .. stepCount - 1:
    currentValue = coeffA[currentVault] * currentValue + coeffB[currentVault]
    currentVault = int(currentValue mod int64(vaultCount))
  appendOutput($currentVault)
  appendOutput(" ")
  appendOutput($currentValue)
  appendOutput("\n")

if outputBuffer.len > 0:
  stdout.write outputBuffer
  outputBuffer.setLen 0

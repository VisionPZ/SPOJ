const flushBlockBytes = 1 shl 17
const registerBits = 16
const registerModulus = 1 shl registerBits

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

proc nextOperation(data: string, pos: var int, isMultiply: var bool, operand: var int) =
  while pos < data.len and (data[pos] < 'A' or data[pos] > 'Z'):
    pos += 1
  if pos >= data.len:
    isMultiply = false
    operand = 0
    return
  isMultiply = data[pos] == 'M'
  operand = nextInt(data, pos)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let instructionCount = nextInt(inputData, scanPos)
  if instructionCount == 0:
    break
  var residue: int64 = 0
  var stepExponent = 0
  for instructionIndex in 0 .. instructionCount - 1:
    var isMultiply = false
    var operand = 0
    nextOperation(inputData, scanPos, isMultiply, operand)
    if isMultiply:
      var trailingZeros = 0
      var factor = operand
      while trailingZeros < registerBits and factor mod 2 == 0:
        trailingZeros += 1
        factor = factor div 2
      stepExponent = stepExponent + trailingZeros
      if stepExponent > registerBits:
        stepExponent = registerBits
      residue = (residue * int64(operand)) mod int64(registerModulus)
    else:
      residue = (residue + int64(operand)) mod int64(registerModulus)
  let possibleValues = int64(1) shl (registerBits - stepExponent)
  appendOutput($possibleValues)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

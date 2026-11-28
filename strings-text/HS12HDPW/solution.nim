const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextCharacter(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let symbol = data[pos]
  pos += 1
  return symbol

proc nextInteger(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var signValue = 1
  if data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInteger(inputData, scanPos)
for _ in 0 ..< caseCount:
  let tupleCount = nextInteger(inputData, scanPos)
  var firstString = ""
  for _ in 0 ..< tupleCount * 6:
    firstString.add nextCharacter(inputData, scanPos)
  var secondString = ""
  for _ in 0 ..< 64:
    secondString.add nextCharacter(inputData, scanPos)
  for tupleIndex in 0 ..< tupleCount:
    let tupleStart = tupleIndex * 6
    var firstIndex = 0
    var secondIndex = 0
    for bitIndex in 0 ..< 6:
      let characterCode = int(firstString[tupleStart + bitIndex])
      let pairedBit = (bitIndex + 3) mod 6
      if (characterCode and (1 shl bitIndex)) != 0:
        firstIndex = firstIndex or (1 shl bitIndex)
      if (characterCode and (1 shl pairedBit)) != 0:
        secondIndex = secondIndex or (1 shl bitIndex)
    appendOutput($secondString[firstIndex])
    appendOutput($secondString[secondIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer

const firstDigitValue = 48

proc readAllInput(): string =
  var inputBuffer = ""
  var inputLine = ""
  while readLine(stdin, inputLine):
    inputBuffer.add inputLine
    inputBuffer.add '\n'
  return inputBuffer

proc nextInteger(inputData: string, scanPos: var int, value: var int): bool =
  var position = scanPos
  var accumulator = 0
  var foundDigit = false
  while position < inputData.len:
    let charValue = int(inputData[position]) - firstDigitValue
    if charValue >= 0 and charValue <= 9:
      accumulator = accumulator * 10 + charValue
      foundDigit = true
      position += 1
    elif foundDigit:
      break
    else:
      position += 1
  scanPos = position
  value = accumulator
  return foundDigit

proc appendDecrypted(outputBuffer: var string, encryptedValue: int) =
  let decryptedValue = encryptedValue + 1
  if decryptedValue >= 1000:
    outputBuffer.add $decryptedValue
  else:
    if decryptedValue < 100:
      outputBuffer.add '0'
    if decryptedValue < 10:
      outputBuffer.add '0'
    outputBuffer.add $decryptedValue
  outputBuffer.add '\n'

var inputData = readAllInput()
var scanPos = 0
var outputBuffer = ""
while true:
  var encryptedValue = 0
  if not nextInteger(inputData, scanPos, encryptedValue):
    break
  appendDecrypted(outputBuffer, encryptedValue)
stdout.write outputBuffer

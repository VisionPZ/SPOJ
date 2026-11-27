const firstDigitValue = 48

proc readInputStream(): string =
  var inputBuffer = ""
  var inputLine = ""
  while readLine(stdin, inputLine):
    inputBuffer.add inputLine
    inputBuffer.add '\n'
  return inputBuffer

proc nextInteger(inputData: string, i: var int, value: var int): bool =
  var j = i
  var accumulator = 0
  var foundDigit = false
  while j < inputData.len:
    let charValue = int(inputData[j]) - firstDigitValue
    if charValue >= 0 and charValue <= 9:
      accumulator = accumulator * 10 + charValue
      foundDigit = true
      j += 1
    elif foundDigit:
      break
    else:
      j += 1
  i = j
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

var inputData = readInputStream()
var i = 0
var outputBuffer = ""
while true:
  var encryptedValue = 0
  if not nextInteger(inputData, i, encryptedValue):
    break
  appendDecrypted(outputBuffer, encryptedValue)
stdout.write outputBuffer

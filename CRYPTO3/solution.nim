var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
while scanPos < inputData.len and inputData[scanPos] <= ' ':
  scanPos += 1

var numberDigits = newSeq[byte]()
while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
  numberDigits.add byte(int(inputData[scanPos]) - 48)
  scanPos += 1

var doubledDigits = newSeq[byte](numberDigits.len + 1)
var carry = 0
for index in 0..<numberDigits.len:
  let sourceIndex = numberDigits.len - 1 - index
  let doubledValue = numberDigits[sourceIndex] * 2 + byte(carry)
  doubledDigits[doubledDigits.len - 1 - index] = doubledValue mod 10
  carry = int(doubledValue div 10)
doubledDigits[0] = byte(carry)

var firstSignificant = 0
while firstSignificant < doubledDigits.len - 1 and doubledDigits[firstSignificant] == 0:
  firstSignificant += 1

var outputBuffer = ""
for index in firstSignificant..<doubledDigits.len:
  outputBuffer.add char(int(doubledDigits[index]) + 48)
outputBuffer.add '\n'
stdout.write outputBuffer

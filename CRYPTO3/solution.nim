var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0
while i < inputData.len and inputData[i] <= ' ':
  i += 1

var numberDigits = newSeq[byte]()
while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
  numberDigits.add byte(int(inputData[i]) - 48)
  i += 1

var doubledDigits = newSeq[byte](numberDigits.len + 1)
var carry = 0
for j in 0..<numberDigits.len:
  let k = numberDigits.len - 1 - j
  let doubledValue = numberDigits[k] * 2 + byte(carry)
  doubledDigits[doubledDigits.len - 1 - j] = doubledValue mod 10
  carry = int(doubledValue div 10)
doubledDigits[0] = byte(carry)

var l = 0
while l < doubledDigits.len - 1 and doubledDigits[l] == 0:
  l += 1

var outputBuffer = ""
for j in l..<doubledDigits.len:
  outputBuffer.add char(int(doubledDigits[j]) + 48)
outputBuffer.add '\n'
stdout.write outputBuffer

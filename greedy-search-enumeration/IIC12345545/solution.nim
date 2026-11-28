var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
  scanPos += 1

if scanPos < inputData.len:
  stdout.write inputData[scanPos]
else:
  stdout.write '0'
stdout.write '\n'

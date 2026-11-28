proc nextInt(inputData: string, pos: var int): int =
  while pos < inputData.len and inputData[pos] != '-' and
        (inputData[pos] < '0' or inputData[pos] > '9'):
    pos += 1
  var signValue = 1
  if pos < inputData.len and inputData[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < inputData.len and inputData[pos] >= '0' and inputData[pos] <= '9':
    value = value * 10 + int(inputData[pos]) - 48
    pos += 1
  return signValue * value

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var pos = 0
let firstCount = nextInt(inputData, pos)
var firstValues: seq[int] = @[]
for _ in 0 ..< firstCount:
  firstValues.add nextInt(inputData, pos)
let secondCount = nextInt(inputData, pos)
var secondValues: seq[int] = @[]
for _ in 0 ..< secondCount:
  secondValues.add nextInt(inputData, pos)

var firstTotal = 0
for value in firstValues:
  firstTotal += value
var secondTotal = 0
for value in secondValues:
  secondTotal += value

var chosenValues: seq[int]
if secondTotal * firstCount < firstTotal * secondCount:
  chosenValues = firstValues
else:
  chosenValues = secondValues

var outputBuffer = ""
for index in 0 ..< chosenValues.len:
  if index > 0:
    outputBuffer.add ' '
  outputBuffer.add $chosenValues[index]
outputBuffer.add '\n'
stdout.write outputBuffer

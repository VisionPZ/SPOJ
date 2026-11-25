const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const answerModulus = 1000000007
const maxPlayers = 1000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and data[position] <= ' ':
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var powersOfTwo: seq[int64]
powersOfTwo.setLen(maxPlayers + 1)
powersOfTwo[0] = 1
for exponent in 1..maxPlayers:
  powersOfTwo[exponent] = powersOfTwo[exponent - 1] * 2 mod int64(answerModulus)

while true:
  let playerCount = nextInt(inputData, scanPos)
  if playerCount == 0:
    break
  if scanPos > inputData.len:
    break
  let firstFactor = int64(playerCount) mod int64(answerModulus)
  let secondFactor = int64(playerCount - 1) mod int64(answerModulus)
  let orderedPairs = firstFactor * secondFactor mod int64(answerModulus)
  let answer = orderedPairs * powersOfTwo[playerCount - 2] mod int64(answerModulus)
  appendOutput($(answer) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextIntOrNegative(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  if position >= data.len:
    return -1
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

while true:
  let targetSum = nextIntOrNegative(inputData, scanPos)
  if targetSum < 0:
    break
  var lowTens = targetSum - 9
  if lowTens < 1:
    lowTens = 1
  var highTens = targetSum
  if highTens > 9:
    highTens = 9
  var foundAny = false
  for tensDigit in lowTens..highTens:
    let onesDigit = targetSum - tensDigit
    appendOutput($(tensDigit * 10 + onesDigit))
    appendOutput(" = ")
    appendOutput($(tensDigit))
    appendOutput(" + ")
    appendOutput($(onesDigit))
    appendOutput(" = ")
    appendOutput($(targetSum))
    appendOutput("\n")
    foundAny = true
  if not foundAny:
    appendOutput("NO\n")

stdout.write outputBuffer
outputBuffer.setLen 0

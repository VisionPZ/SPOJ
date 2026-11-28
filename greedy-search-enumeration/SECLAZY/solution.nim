const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var scanPos = 0

while true:
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  if scanPos >= inputData.len:
    break
  let contestantCount = nextInt(inputData, scanPos)
  let firstPrizeCount = nextInt(inputData, scanPos)
  let secondPrizeCount = nextInt(inputData, scanPos)
  let thirdPrizeCount = nextInt(inputData, scanPos)
  let fourthPrizeCount = nextInt(inputData, scanPos)
  let awardedCount = firstPrizeCount + secondPrizeCount + thirdPrizeCount + fourthPrizeCount
  if awardedCount * 2 >= contestantCount:
    appendOutput("YES\n")
  else:
    appendOutput("NO\n")

stdout.write outputBuffer
outputBuffer.setLen 0

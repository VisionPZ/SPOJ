const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

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

proc nextToken(data: string, position: var int): string =
  while position < data.len and data[position] <= ' ':
    position += 1
  var token = ""
  while position < data.len and data[position] > ' ':
    token.add data[position]
    position += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let numberToken = nextToken(inputData, scanPos)
  var lastDigit = numberToken.len - 1
  while lastDigit >= 0 and numberToken[lastDigit] == '0':
    lastDigit -= 1
  var isPalindrome = true
  var leftDigit = 0
  while leftDigit < lastDigit:
    if numberToken[leftDigit] != numberToken[lastDigit]:
      isPalindrome = false
      break
    leftDigit += 1
    lastDigit -= 1
  if isPalindrome:
    appendOutput("YES\n")
  else:
    appendOutput("NO\n")

stdout.write outputBuffer
outputBuffer.setLen 0

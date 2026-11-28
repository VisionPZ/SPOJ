const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const answerYes = "YES"
const answerNo = "NO"

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let startPos = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[startPos ..< pos]

proc isUpper(c: char): bool =
  return c >= 'A' and c <= 'Z'

proc isLower(c: char): bool =
  return c >= 'a' and c <= 'z'

proc isDigit(c: char): bool =
  return c >= '0' and c <= '9'

proc isValid(password: string): bool =
  if password.len < 6 or password.len > 20:
    return false
  var hasUpper = false
  var hasLower = false
  var hasDigit = false
  var hasSpecial = false
  for c in password:
    if isUpper(c):
      hasUpper = true
    elif isLower(c):
      hasLower = true
    elif isDigit(c):
      hasDigit = true
    else:
      hasSpecial = true
  if not (hasUpper and hasLower and hasDigit and hasSpecial):
    return false
  for i in 0 ..< password.len - 3:
    if password[i] == password[i + 2] and password[i + 1] == password[i + 3]:
      return false
  for i in 0 ..< password.len - 5:
    if password[i] == password[i + 3] and password[i + 1] == password[i + 4] and
       password[i + 2] == password[i + 5]:
      return false
  return true

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = int(nextInt(inputData, scanPos))
for j in 0..<caseCount:
  let password = nextToken(inputData, scanPos)
  if isValid(password):
    appendOutput(answerYes)
  else:
    appendOutput(answerNo)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

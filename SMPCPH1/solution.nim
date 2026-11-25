const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, pos: var int): int =
  while pos < inputData.len and (inputData[pos] < '0' or inputData[pos] > '9'):
    pos += 1
  var value = 0
  while pos < inputData.len and inputData[pos] >= '0' and inputData[pos] <= '9':
    value = value * 10 + int(inputData[pos]) - 48
    pos += 1
  return value

proc readKey(inputData: string, pos: var int, keyLength: int): string =
  result = ""
  while result.len < keyLength:
    while pos < inputData.len and inputData[pos] <= ' ':
      pos += 1
    if pos >= inputData.len:
      break
    result.add inputData[pos]
    pos += 1

proc trimLine(lineBuffer: var string) =
  while lineBuffer.len > 0:
    let lastChar = lineBuffer[lineBuffer.len - 1]
    if lastChar == ' ' or lastChar == '\t' or lastChar == '\r':
      lineBuffer.setLen lineBuffer.len - 1
    else:
      break

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var pos = 0
let keyLength = nextInt(inputData, pos)
let cipherKey = readKey(inputData, pos, keyLength)
let plaintextLineCount = nextInt(inputData, pos)

var substitution: array[26, char]
for index in 0 ..< 26:
  substitution[index] = chr(97 + index)
for index in 0 ..< keyLength:
  let sourceChar = cipherKey[index]
  let targetChar = cipherKey[(index + 1) mod keyLength]
  substitution[ord(sourceChar) - 97] = targetChar

while pos < inputData.len and inputData[pos] != '\n':
  pos += 1
if pos < inputData.len:
  pos += 1

var outputBuffer = ""
var lineBuffer = ""
for _ in 0 ..< plaintextLineCount:
  lineBuffer.setLen 0
  while pos < inputData.len and inputData[pos] != '\n':
    let currentChar = inputData[pos]
    pos += 1
    if currentChar >= 'a' and currentChar <= 'z':
      lineBuffer.add substitution[ord(currentChar) - 97]
    else:
      lineBuffer.add currentChar
  if pos < inputData.len:
    pos += 1
  trimLine lineBuffer
  outputBuffer.add lineBuffer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer

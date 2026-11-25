const flushBlockBytes = 1 shl 17

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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc isWordCharacter(letter: char): bool =
  return (letter >= 'a' and letter <= 'z') or (letter >= 'A' and letter <= 'Z') or (letter >= '0' and letter <= '9')

proc loweredCharacter(letter: char): char =
  if letter >= 'A' and letter <= 'Z':
    return chr(int(letter) + 32)
  return letter

proc isPalindromePhrase(phrase: string): bool =
  var leftIndex = 0
  var rightIndex = phrase.len - 1
  while leftIndex < rightIndex:
    while leftIndex < rightIndex and not isWordCharacter(phrase[leftIndex]):
      leftIndex += 1
    while leftIndex < rightIndex and not isWordCharacter(phrase[rightIndex]):
      rightIndex -= 1
    if loweredCharacter(phrase[leftIndex]) != loweredCharacter(phrase[rightIndex]):
      return false
    leftIndex += 1
    rightIndex -= 1
  return true

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var lineStart = 0
while lineStart < inputData.len:
  var lineEnd = lineStart
  while lineEnd < inputData.len and inputData[lineEnd] != '\n':
    lineEnd += 1
  let phrase = inputData[lineStart .. lineEnd - 1]
  appendOutput(phrase)
  if isPalindromePhrase(phrase):
    appendOutput(" is a palindrome")
  else:
    appendOutput(" is not a palindrome")
  outputBuffer.add '\n'
  lineStart = lineEnd + 1
stdout.write outputBuffer
outputBuffer.setLen 0

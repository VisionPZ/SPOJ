const flushBlockBytes = 1 shl 17
const ignoredWords = ["a", "in", "is", "on", "of", "and", "the", "for"]

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

proc nextRawLine(data: string, pos: var int): string =
  if pos >= data.len:
    return ""
  var lineEnd = pos
  while lineEnd < data.len and data[lineEnd] != '\n':
    lineEnd += 1
  let rawText = data[pos .. lineEnd - 1]
  pos = lineEnd + 1
  return rawText

proc trimmedWord(rawWord: string): string =
  var firstIndex = 0
  var lastIndex = rawWord.len - 1
  while firstIndex <= lastIndex and rawWord[firstIndex] == ' ':
    firstIndex += 1
  while lastIndex >= firstIndex and rawWord[lastIndex] == ' ':
    lastIndex -= 1
  if firstIndex > lastIndex:
    return ""
  return rawWord[firstIndex .. lastIndex]

proc loweredCharacter(letter: char): char =
  if letter >= 'A' and letter <= 'Z':
    return chr(int(letter) + 32)
  return letter

proc upperCharacter(letter: char): char =
  if letter >= 'a' and letter <= 'z':
    return chr(int(letter) - 32)
  return letter

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let wordCount = nextInt(inputData, scanPos)
discard nextRawLine(inputData, scanPos)
for wordIndex in 0 .. wordCount - 1:
  let rawWord = nextRawLine(inputData, scanPos)
  let wordText = trimmedWord(rawWord)
  var loweredWord = ""
  for letterIndex in 0 .. wordText.len - 1:
    loweredWord.add loweredCharacter(wordText[letterIndex])
  var ignored = false
  for ignoredWord in ignoredWords:
    if loweredWord == ignoredWord:
      ignored = true
  if not ignored and wordText.len > 0:
    appendOutput($upperCharacter(wordText[0]))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

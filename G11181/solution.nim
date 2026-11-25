import algorithm

const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc isLetter(character: char): bool =
  return (character >= 'a' and character <= 'z') or (character >= 'A' and character <= 'Z')

proc compareWords(leftWord: string, rightWord: string): int =
  if leftWord < rightWord:
    return -1
  if leftWord > rightWord:
    return 1
  return 0

var distinctWords = newSeq[string](0)
var scanPos = 0
while scanPos < inputData.len:
  if isLetter(inputData[scanPos]):
    var loweredWord = ""
    while scanPos < inputData.len:
      var character = inputData[scanPos]
      if character >= 'A' and character <= 'Z':
        character = chr(ord(character) + 32)
      if not isLetter(character):
        break
      loweredWord.add character
      scanPos += 1
    distinctWords.add loweredWord
  else:
    scanPos += 1

distinctWords.sort(compareWords)
var wordIndex = 0
while wordIndex < distinctWords.len:
  if wordIndex > 0 and distinctWords[wordIndex] == distinctWords[wordIndex - 1]:
    wordIndex += 1
    continue
  appendOutput(distinctWords[wordIndex])
  appendOutput("\n")
  wordIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0

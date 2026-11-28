import algorithm

const flushBlockBytes = 1 shl 17
const firstUpperValue = 65
const lastUpperValue = 90
const firstLowerValue = 97
const lastLowerValue = 122
const lowercaseShift = 32

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

proc compareWords(leftWord: string, rightWord: string): int =
  if leftWord < rightWord:
    return -1
  if leftWord > rightWord:
    return 1
  return 0

var seenWords: seq[string] = @[]
var currentWord = ""
for byteCharacter in inputData:
  let byteCode = ord(byteCharacter)
  if byteCode >= firstUpperValue and byteCode <= lastUpperValue:
    currentWord.add chr(byteCode + lowercaseShift)
  elif byteCode >= firstLowerValue and byteCode <= lastLowerValue:
    currentWord.add chr(byteCode)
  else:
    if currentWord.len > 0:
      seenWords.add currentWord
      currentWord.setLen 0
if currentWord.len > 0:
  seenWords.add currentWord
  currentWord.setLen 0

sort(seenWords, compareWords)

var previousWord = ""
for word in seenWords:
  if word != previousWord:
    appendOutput(word)
    appendOutput("\n")
    previousWord = word

stdout.write outputBuffer
outputBuffer.setLen 0

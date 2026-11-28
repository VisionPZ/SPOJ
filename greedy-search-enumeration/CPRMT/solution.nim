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

var firstLetterCounts = newSeq[int](26)
var secondLetterCounts = newSeq[int](26)
var scanPos = 0
var pairPosition = 0

while scanPos < inputData.len:
  var nextWord = ""
  while scanPos < inputData.len and inputData[scanPos] >= 'a' and inputData[scanPos] <= 'z':
    nextWord.add inputData[scanPos]
    scanPos += 1
  if nextWord.len == 0:
    scanPos += 1
    continue
  if pairPosition == 0:
    for letterChar in nextWord:
      firstLetterCounts[int(letterChar) - 97] += 1
    pairPosition = 1
  else:
    for letterChar in nextWord:
      secondLetterCounts[int(letterChar) - 97] += 1
    var commonLetters = ""
    for letterIndex in 0 .. 25:
      let sharedCount = min(firstLetterCounts[letterIndex], secondLetterCounts[letterIndex])
      for repeatIndex in 0 ..< sharedCount:
        commonLetters.add chr(97 + letterIndex)
    appendOutput(commonLetters)
    outputBuffer.add '\n'
    for letterIndex in 0 .. 25:
      firstLetterCounts[letterIndex] = 0
      secondLetterCounts[letterIndex] = 0
    pairPosition = 0

stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

proc isVowelLetter(value: char): bool =
  return value == 'a' or value == 'e' or value == 'i' or
         value == 'o' or value == 'u'

proc isAcceptable(word: string): bool =
  if word.len == 0: return false
  var hasVowel = false
  var vowelRun = 0
  var consonantRun = 0
  var previous = char(0)
  for index in 0..<word.len:
    let current = word[index]
    if current == previous and current != 'e' and current != 'o':
      return false
    if isVowelLetter(current):
      hasVowel = true
      vowelRun += 1
      consonantRun = 0
      if vowelRun >= 3: return false
    else:
      consonantRun += 1
      vowelRun = 0
      if consonantRun >= 3: return false
    previous = current
  return hasVowel

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
  var word = ""
  for index in lineStart..<lineEnd:
    let current = inputData[index]
    if current > ' ': word.add current
  if word == "end": break
  if word.len > 0:
    appendOutput("<")
    appendOutput(word)
    if isAcceptable(word):
      appendOutput("> is acceptable.\n")
    else:
      appendOutput("> is not acceptable.\n")
  lineStart = lineEnd + 1

stdout.write outputBuffer
outputBuffer.setLen 0

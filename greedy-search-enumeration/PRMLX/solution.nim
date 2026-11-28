const flushBlockBytes = 1 shl 17
const letterCount = 26
const outputFieldWidth = 10
const firstLetterCode = 97
const rankCeiling: int64 = 1 shl 40

var binomial: array[0 .. 30, array[0 .. 30, int64]]
for totalLetters in 0 .. 30:
  binomial[totalLetters][0] = 1
  binomial[totalLetters][totalLetters] = 1
  for chosenLetters in 1 .. totalLetters - 1:
    binomial[totalLetters][chosenLetters] = binomial[totalLetters - 1][chosenLetters - 1] + binomial[totalLetters - 1][chosenLetters]

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

proc permutationCount(frequencies: array[0 .. 25, int]): int64 =
  var placedLetters = 0
  result = 1
  for letterIndex in 0 .. letterCount - 1:
    placedLetters = placedLetters + frequencies[letterIndex]
    let factor = binomial[placedLetters][frequencies[letterIndex]]
    if result > rankCeiling div factor:
      return rankCeiling
    result = result * factor

var scanPos = 0
while scanPos < inputData.len:
  var lineEnd = scanPos
  while lineEnd < inputData.len and inputData[lineEnd] != '\n':
    lineEnd += 1
  var word = inputData[scanPos .. lineEnd - 1]
  if word.len > 0 and word[word.len - 1] == '\r':
    word.setLen word.len - 1
  if word == "#":
    break
  var frequencies: array[0 .. 25, int]
  for letterIndex in 0 .. letterCount - 1:
    frequencies[letterIndex] = 0
  for character in word:
    let letterIndex = int(character) - firstLetterCode
    if letterIndex >= 0 and letterIndex < letterCount:
      frequencies[letterIndex] += 1
  var rankValue: int64 = 1
  for position in 0 .. word.len - 1:
    let actualLetter = int(word[position]) - firstLetterCode
    if actualLetter >= 0 and actualLetter < letterCount:
      for smallerLetter in 0 .. actualLetter - 1:
        if frequencies[smallerLetter] == 0:
          continue
        frequencies[smallerLetter] -= 1
        rankValue = rankValue + permutationCount(frequencies)
        frequencies[smallerLetter] += 1
      frequencies[actualLetter] -= 1
  var rankText = $rankValue
  while rankText.len < outputFieldWidth:
    rankText = " " & rankText
  appendOutput(rankText)
  appendOutput("\n")
  scanPos = lineEnd + 1

stdout.write outputBuffer
outputBuffer.setLen 0

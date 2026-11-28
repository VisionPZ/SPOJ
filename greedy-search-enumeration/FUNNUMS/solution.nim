const flushBlockBytes = 1 shl 17
const letterBase = 97
const maxWordLength = 15

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var word = ""
  while pos < data.len and data[pos] > ' ':
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var factorials = newSeq[int64](maxWordLength + 1)
factorials[0] = 1
for sizeIndex in 1 .. maxWordLength:
  factorials[sizeIndex] = factorials[sizeIndex - 1] * int64(sizeIndex)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let permutationText = nextWord(inputData, scanPos)
  let shiftCount = int64(nextInt(inputData, scanPos))
  let wordLength = permutationText.len
  var availableLetters = newSeq[bool](wordLength)
  for letterIndex in 0 .. wordLength - 1:
    availableLetters[letterIndex] = true
  var rankValue: int64 = 0
  for posIndex in 0 .. wordLength - 1:
    let letterIndex = int(permutationText[posIndex]) - letterBase
    var smallerCount = 0
    for candidate in 0 .. letterIndex - 1:
      if availableLetters[candidate]:
        smallerCount += 1
    rankValue = rankValue + int64(smallerCount) * factorials[wordLength - 1 - posIndex]
    availableLetters[letterIndex] = false
  rankValue = rankValue + shiftCount
  for letterIndex in 0 .. wordLength - 1:
    availableLetters[letterIndex] = true
  var answerText = ""
  for posIndex in 0 .. wordLength - 1:
    let blockSize = factorials[wordLength - 1 - posIndex]
    let chosenIndex = int(rankValue div blockSize)
    rankValue = rankValue mod blockSize
    var seenCount = 0
    for candidate in 0 .. wordLength - 1:
      if availableLetters[candidate]:
        if seenCount == chosenIndex:
          answerText.add char(candidate + letterBase)
          availableLetters[candidate] = false
          break
        seenCount += 1
  appendOutput(answerText)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

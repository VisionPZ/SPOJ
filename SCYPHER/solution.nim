import sequtils

const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const baseLetterValue = 97

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - firstDigitValue
    i = i + 1
  return value

proc skipToNextLine(inputData: string, i: var int) =
  while i < inputData.len and inputData[i] != '\n': i = i + 1
  if i < inputData.len: i = i + 1

proc readWord(inputData: string, i: var int, wordBegin: var int, wordEnd: var int) =
  while i < inputData.len and (inputData[i] == '\n' or inputData[i] == '\r' or inputData[i] == ' '): i = i + 1
  wordBegin = i
  while i < inputData.len and inputData[i] != '\n' and inputData[i] != '\r' and inputData[i] != ' ': i = i + 1
  wordEnd = i

proc solveCase(inputData: string, i: var int, outputBuffer: var string) =
  let alphabetSize = nextInt(inputData, i)
  let wordCount = nextInt(inputData, i)
  skipToNextLine(inputData, i)
  var reach = repeat(false, alphabetSize * alphabetSize)
  var havePrevious = false
  var previousBegin = 0
  var previousEnd = 0
  for j in 1 .. wordCount:
    var currentBegin = 0
    var currentEnd = 0
    readWord(inputData, i, currentBegin, currentEnd)
    if havePrevious:
      let sharedLength = min(previousEnd - previousBegin, currentEnd - currentBegin)
      var diffPos = 0
      while diffPos < sharedLength and inputData[previousBegin + diffPos] == inputData[currentBegin + diffPos]:
        diffPos = diffPos + 1
      if diffPos < sharedLength:
        let leftLetter = int(inputData[previousBegin + diffPos]) - baseLetterValue
        let rightLetter = int(inputData[currentBegin + diffPos]) - baseLetterValue
        reach[leftLetter * alphabetSize + rightLetter] = true
    previousBegin = currentBegin
    previousEnd = currentEnd
    havePrevious = true
  skipToNextLine(inputData, i)
  let messageBegin = i
  while i < inputData.len and inputData[i] != '\n': i = i + 1
  let messageEnd = i
  skipToNextLine(inputData, i)
  for j in 0 .. alphabetSize - 1:
    for k in 0 .. alphabetSize - 1:
      if reach[k * alphabetSize + j]:
        for l in 0 .. alphabetSize - 1:
          if reach[j * alphabetSize + l]:
            reach[k * alphabetSize + l] = true
  var decryptable = true
  for j in 0 .. alphabetSize - 1:
    if reach[j * alphabetSize + j]: decryptable = false
  if decryptable:
    for k in 0 .. alphabetSize - 1:
      if k + 1 < alphabetSize:
        for l in k + 1 .. alphabetSize - 1:
          if not reach[k * alphabetSize + l] and not reach[l * alphabetSize + k]:
            decryptable = false
  if not decryptable:
    outputBuffer.add "Message cannot be decrypted.\n"
  else:
    var rankTable = newSeq[int](alphabetSize)
    for l in 0 .. alphabetSize - 1:
      var predecessorCount = 0
      for k in 0 .. alphabetSize - 1:
        if k != l and reach[k * alphabetSize + l]:
          predecessorCount = predecessorCount + 1
      rankTable[l] = predecessorCount
    if messageEnd > messageBegin:
      for j in messageBegin .. messageEnd - 1:
        let symbol = inputData[j]
        if symbol >= 'a' and symbol <= chr(baseLetterValue + alphabetSize - 1):
          outputBuffer.add chr(baseLetterValue + rankTable[int(symbol) - baseLetterValue])
        else:
          outputBuffer.add symbol
    outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var i = 0
let caseCount = nextInt(inputData, i)
var outputBuffer: string
for j in 1 .. caseCount:
  solveCase(inputData, i, outputBuffer)
stdout.write outputBuffer

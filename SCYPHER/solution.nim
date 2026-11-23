import sequtils

const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const baseLetterValue = 97

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ': scanPos = scanPos + 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos = scanPos + 1
  return value

proc skipToNextLine(inputData: string, scanPos: var int) =
  while scanPos < inputData.len and inputData[scanPos] != '\n': scanPos = scanPos + 1
  if scanPos < inputData.len: scanPos = scanPos + 1

proc readWord(inputData: string, scanPos: var int, wordBegin: var int, wordEnd: var int) =
  while scanPos < inputData.len and (inputData[scanPos] == '\n' or inputData[scanPos] == '\r' or inputData[scanPos] == ' '): scanPos = scanPos + 1
  wordBegin = scanPos
  while scanPos < inputData.len and inputData[scanPos] != '\n' and inputData[scanPos] != '\r' and inputData[scanPos] != ' ': scanPos = scanPos + 1
  wordEnd = scanPos

proc solveCase(inputData: string, scanPos: var int, outputBuffer: var string) =
  let alphabetSize = nextInt(inputData, scanPos)
  let wordCount = nextInt(inputData, scanPos)
  skipToNextLine(inputData, scanPos)
  var reach = repeat(false, alphabetSize * alphabetSize)
  var havePrevious = false
  var previousBegin = 0
  var previousEnd = 0
  for wordIndex in 1 .. wordCount:
    var currentBegin = 0
    var currentEnd = 0
    readWord(inputData, scanPos, currentBegin, currentEnd)
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
  skipToNextLine(inputData, scanPos)
  let messageBegin = scanPos
  while scanPos < inputData.len and inputData[scanPos] != '\n': scanPos = scanPos + 1
  let messageEnd = scanPos
  skipToNextLine(inputData, scanPos)
  for midLetter in 0 .. alphabetSize - 1:
    for fromLetter in 0 .. alphabetSize - 1:
      if reach[fromLetter * alphabetSize + midLetter]:
        for toLetter in 0 .. alphabetSize - 1:
          if reach[midLetter * alphabetSize + toLetter]:
            reach[fromLetter * alphabetSize + toLetter] = true
  var decryptable = true
  for letterIndex in 0 .. alphabetSize - 1:
    if reach[letterIndex * alphabetSize + letterIndex]: decryptable = false
  if decryptable:
    for fromLetter in 0 .. alphabetSize - 1:
      if fromLetter + 1 < alphabetSize:
        for toLetter in fromLetter + 1 .. alphabetSize - 1:
          if not reach[fromLetter * alphabetSize + toLetter] and not reach[toLetter * alphabetSize + fromLetter]:
            decryptable = false
  if not decryptable:
    outputBuffer.add "Message cannot be decrypted.\n"
  else:
    var rankTable = newSeq[int](alphabetSize)
    for toLetter in 0 .. alphabetSize - 1:
      var predecessorCount = 0
      for fromLetter in 0 .. alphabetSize - 1:
        if fromLetter != toLetter and reach[fromLetter * alphabetSize + toLetter]:
          predecessorCount = predecessorCount + 1
      rankTable[toLetter] = predecessorCount
    if messageEnd > messageBegin:
      for messagePos in messageBegin .. messageEnd - 1:
        let symbol = inputData[messagePos]
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
var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer: string
for caseIndex in 1 .. caseCount:
  solveCase(inputData, scanPos, outputBuffer)
stdout.write outputBuffer

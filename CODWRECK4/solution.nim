import algorithm

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc compareWords(leftWord: string, rightWord: string): int =
  cmp(leftWord, rightWord)

proc containsWord(sortedWords: seq[string], target: string): bool =
  var lowIndex = 0
  var highIndex = sortedWords.len - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    let comparison = cmp(sortedWords[middleIndex], target)
    if comparison < 0:
      lowIndex = middleIndex + 1
    elif comparison > 0:
      highIndex = middleIndex - 1
    else:
      return true
  return false

let wordCount = nextInt(inputData, scanPos)
var dictionary = newSeq[string](wordCount)
for wordIndex in 0 .. wordCount - 1:
  dictionary[wordIndex] = nextToken(inputData, scanPos)
dictionary.sort(compareWords)

let messageCount = nextInt(inputData, scanPos)
for messageIndex in 0 .. messageCount - 1:
  let alienMessage = nextToken(inputData, scanPos)
  for splitIndex in 1 .. alienMessage.len - 1:
    let firstWord = alienMessage[0 .. splitIndex - 1]
    let secondWord = alienMessage[splitIndex .. alienMessage.len - 1]
    if containsWord(dictionary, firstWord) and containsWord(dictionary, secondWord):
      appendOutput(firstWord)
      outputBuffer.add ' '
      appendOutput(secondWord)
      outputBuffer.add '\n'
      break

stdout.write outputBuffer
outputBuffer.setLen 0

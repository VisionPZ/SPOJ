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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < 'a' or data[pos] > 'z'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'a' and data[pos] <= 'z':
    word.add data[pos]
    pos += 1
  return word

proc compareWords(leftWord, rightWord: string): int =
  return cmp(leftWord, rightWord)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let inputCount = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
var wordList = newSeq[string](inputCount)
for wordIndex in 0 .. inputCount - 1:
  wordList[wordIndex] = nextWord(inputData, scanPos)
wordList.sort(compareWords)

for queryIndex in 0 .. queryCount - 1:
  let queryWord = nextWord(inputData, scanPos)
  var lowBound = 0
  var highBound = wordList.len
  while lowBound < highBound:
    let middleIndex = (lowBound + highBound) div 2
    if wordList[middleIndex] <= queryWord:
      lowBound = middleIndex + 1
    else:
      highBound = middleIndex
  appendOutput($lowBound)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0

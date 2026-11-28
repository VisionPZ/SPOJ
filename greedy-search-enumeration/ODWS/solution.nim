const flushBlockBytes = 1 shl 17
const alphabetSize = 26
const firstLetterCode = 97
const modulusValue = 1000000007

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

proc nextLowerWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < 'a' or data[pos] > 'z'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'a' and data[pos] <= 'z':
    word.add data[pos]
    pos += 1
  return word

proc wordRank(word: string): int64 =
  var rankValue: int64 = 0
  for letter in word:
    rankValue = (rankValue * alphabetSize + int64(int(letter) - firstLetterCode)) mod modulusValue
  return rankValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let lowerWord = nextLowerWord(inputData, scanPos)
  let upperWord = nextLowerWord(inputData, scanPos)
  let lowerRank = wordRank(lowerWord)
  let upperRank = wordRank(upperWord)
  let betweenCount = (upperRank - lowerRank - 1 + modulusValue) mod modulusValue
  appendOutput("Case " & $caseIndex & ": " & $betweenCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

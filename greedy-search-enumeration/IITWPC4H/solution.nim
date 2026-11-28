const flushBlockBytes = 1 shl 17
const alphabetSize = 26
const firstLetterCode = 97

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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let firstString = nextToken(inputData, scanPos)
  let secondString = nextToken(inputData, scanPos)
  var longestFirstRuns: array[alphabetSize, int]
  var previousLetter = -1
  var currentRun = 0
  for letter in firstString:
    let letterIndex = int(letter) - firstLetterCode
    if letterIndex == previousLetter:
      currentRun += 1
    else:
      currentRun = 1
      previousLetter = letterIndex
    if currentRun > longestFirstRuns[letterIndex]:
      longestFirstRuns[letterIndex] = currentRun
  var cuteness = 0
  for letterIndex in 0 .. alphabetSize - 1:
    if longestFirstRuns[letterIndex] > cuteness:
      cuteness = longestFirstRuns[letterIndex]
  previousLetter = -1
  currentRun = 0
  for letter in secondString:
    let letterIndex = int(letter) - firstLetterCode
    if letterIndex == previousLetter:
      currentRun += 1
    else:
      currentRun = 1
      previousLetter = letterIndex
    let combinedRun = longestFirstRuns[letterIndex] + currentRun
    if combinedRun > cuteness:
      cuteness = combinedRun
  appendOutput($cuteness)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

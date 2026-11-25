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
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] != ' ' and data[pos] != '\n' and data[pos] != '\r' and data[pos] != '\t':
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc sortGainsDescending(gains: var seq[int]) =
  for rightIndex in 1 .. gains.len - 1:
    let currentGain = gains[rightIndex]
    var leftIndex = rightIndex - 1
    while leftIndex >= 0 and gains[leftIndex] < currentGain:
      gains[leftIndex + 1] = gains[leftIndex]
      leftIndex -= 1
    gains[leftIndex + 1] = currentGain

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let operationCount = nextInt(inputData, scanPos)
  var gains = newSeq[int](rowCount)
  var litTotal = 0
  for rowIndex in 0 .. rowCount - 1:
    let rowText = nextWord(inputData, scanPos)
    var litCount = 0
    for charIndex in 0 .. rowText.len - 1:
      if rowText[charIndex] == '*':
        litCount += 1
    gains[rowIndex] = columnCount - 2 * litCount
    litTotal += litCount
  sortGainsDescending(gains)
  var bestLit = -1
  var gainSum = 0
  var toggledRows = 0
  while toggledRows <= rowCount and toggledRows <= operationCount:
    if (operationCount - toggledRows) mod 2 == 0:
      let candidate = litTotal + gainSum
      if bestLit < candidate:
        bestLit = candidate
    if toggledRows < rowCount:
      gainSum += gains[toggledRows]
    toggledRows += 1
  appendOutput($bestLit)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

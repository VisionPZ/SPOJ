const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseTotal = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseTotal - 1:
  let scoreCount = nextInt(inputData, scanPos)
  let queryCount = nextInt(inputData, scanPos)
  var logTable = newSeq[int](scoreCount + 1)
  var levelIndex = 2
  while levelIndex <= scoreCount:
    logTable[levelIndex] = logTable[levelIndex div 2] + 1
    levelIndex += 1
  let levelCount = logTable[scoreCount] + 1
  var sparseTable = newSeq[int64](levelCount * scoreCount)
  var scoreIndex = 0
  while scoreIndex < scoreCount:
    sparseTable[scoreIndex] = int64(nextInt(inputData, scanPos))
    scoreIndex += 1
  var tableLevel = 1
  while tableLevel < levelCount:
    let spanLength = 1 shl tableLevel
    let halfSpan = spanLength div 2
    var blockStart = 0
    while blockStart + spanLength <= scoreCount:
      let leftValue = sparseTable[(tableLevel - 1) * scoreCount + blockStart]
      let rightValue = sparseTable[(tableLevel - 1) * scoreCount + blockStart + halfSpan]
      if leftValue < rightValue:
        sparseTable[tableLevel * scoreCount + blockStart] = leftValue
      else:
        sparseTable[tableLevel * scoreCount + blockStart] = rightValue
      blockStart += 1
    tableLevel += 1
  appendOutput("Scenario #" & $(caseIndex + 1) & ":\n")
  var queryIndex = 0
  while queryIndex < queryCount:
    let leftEnd = nextInt(inputData, scanPos) - 1
    let rightEnd = nextInt(inputData, scanPos) - 1
    let rangeLength = rightEnd - leftEnd + 1
    let queryLevel = logTable[rangeLength]
    let jumpLength = 1 shl queryLevel
    let firstValue = sparseTable[queryLevel * scoreCount + leftEnd]
    let secondValue = sparseTable[queryLevel * scoreCount + rightEnd - jumpLength + 1]
    if firstValue < secondValue:
      appendOutput($firstValue)
    else:
      appendOutput($secondValue)
    appendOutput("\n")
    queryIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0

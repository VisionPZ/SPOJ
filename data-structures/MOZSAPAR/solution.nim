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
  result = ""
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let sequence = nextToken(inputData, scanPos)
  let sequenceLength = sequence.len
  var openingCount = 0
  var closingCount = 0
  var questionCount = 0
  for charIndex in 0 .. sequenceLength - 1:
    if sequence[charIndex] == '(':
      openingCount += 1
    elif sequence[charIndex] == ')':
      closingCount += 1
    else:
      questionCount += 1
  let openingsNeeded = (closingCount + questionCount - openingCount) div 2
  var possible = true
  if sequenceLength mod 2 != 0 or openingsNeeded < 0 or openingsNeeded > questionCount:
    possible = false
  var balance = 0
  var questionsUsed = 0
  if possible:
    for charIndex in 0 .. sequenceLength - 1:
      let currentChar = sequence[charIndex]
      if currentChar == '(':
        balance += 1
      elif currentChar == ')':
        balance -= 1
      else:
        if questionsUsed < openingsNeeded:
          balance += 1
        else:
          balance -= 1
        questionsUsed += 1
      if balance < 0:
        possible = false
        break
  if possible and balance == 0:
    appendOutput("yes\n")
  else:
    appendOutput("no\n")
stdout.write outputBuffer
outputBuffer.setLen 0

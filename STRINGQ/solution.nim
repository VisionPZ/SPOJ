const modulus = 106109099
const maxTextLength = 50000
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

proc powMod(baseValue: int64, exponentValue: int64): int64 =
  var powerResult: int64 = 1
  var power = baseValue mod modulus
  var remaining = exponentValue
  while remaining > 0:
    if (remaining and 1) == 1:
      powerResult = powerResult * power mod modulus
    power = power * power mod modulus
    remaining = remaining div 2
  return powerResult

var factorials = newSeq[int64](maxTextLength + 1)
var inverseFactorials = newSeq[int64](maxTextLength + 1)
factorials[0] = 1
for lengthValue in 1 .. maxTextLength:
  factorials[lengthValue] = factorials[lengthValue - 1] * int64(lengthValue) mod modulus
inverseFactorials[maxTextLength] = powMod(factorials[maxTextLength], int64(modulus - 2))
for lengthValue in countDown(maxTextLength, 1):
  inverseFactorials[lengthValue - 1] = inverseFactorials[lengthValue] * int64(lengthValue) mod modulus

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  var currentText = nextToken(inputData, scanPos)
  let queryCount = nextInt(inputData, scanPos)
  for queryIndex in 0 .. queryCount - 1:
    let queryType = nextToken(inputData, scanPos)
    let leftIndex = nextInt(inputData, scanPos) - 1
    let rightIndex = nextInt(inputData, scanPos) - 1
    if queryType[0] == 'U':
      var letterCounts = newSeq[int](26)
      for textIndex in leftIndex .. rightIndex:
        letterCounts[int(currentText[textIndex]) - 97] += 1
      var writeIndex = leftIndex
      for letterIndex in 0 .. 25:
        for repeatIndex in 0 .. letterCounts[letterIndex] - 1:
          currentText[writeIndex] = chr(97 + letterIndex)
          writeIndex += 1
    else:
      var letterCounts = newSeq[int](26)
      var oddGroups = 0
      for textIndex in leftIndex .. rightIndex:
        letterCounts[int(currentText[textIndex]) - 97] += 1
      for letterIndex in 0 .. 25:
        if (letterCounts[letterIndex] and 1) == 1:
          oddGroups += 1
      if oddGroups > 1:
        appendOutput("0")
      else:
        let halfLength = (rightIndex - leftIndex + 1) div 2
        var answerValue = factorials[halfLength]
        for letterIndex in 0 .. 25:
          answerValue = answerValue * inverseFactorials[letterCounts[letterIndex] div 2] mod modulus
        appendOutput($answerValue)
      outputBuffer.add '\n'
  appendOutput(currentText)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

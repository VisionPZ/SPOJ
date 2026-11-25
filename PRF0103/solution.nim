import strutils

const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var numberValue = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    numberValue = numberValue * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * numberValue

proc hasNextNumber(data: string, pos: int): bool =
  var scanIndex = pos
  while scanIndex < data.len and (data[scanIndex] < '0' or data[scanIndex] > '9') and data[scanIndex] != '-':
    scanIndex += 1
  return scanIndex < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

const numeratorPrompt = "Please enter numerator: "
const denominatorPrompt = "Please enter denominator: "
const zeroDenominatorMessage = "The denominator can't be zero!"
const resultPrefix = "Result: "
const resultSeparator = " / "
const resultEquals = " = "

while hasNextNumber(inputData, scanPos):
  let numerator = nextInt(inputData, scanPos)
  let denominator = nextInt(inputData, scanPos)
  appendOutput(numeratorPrompt)
  appendOutput(denominatorPrompt)
  if denominator == 0:
    appendOutput(zeroDenominatorMessage)
  else:
    let quotient = float(numerator) / float(denominator)
    appendOutput(resultPrefix)
    appendOutput($numerator)
    appendOutput(resultSeparator)
    appendOutput($denominator)
    appendOutput(resultEquals)
    appendOutput(formatFloat(quotient, ffDecimal, 6))
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0

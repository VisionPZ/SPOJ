const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const bigBase = 1000000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt(data: string, position: var int): int =
  while position < data.len and data[position] != '-' and (data[position] < '0' or data[position] > '9'):
    position += 1
  var isNegative = false
  if position < data.len and data[position] == '-':
    isNegative = true
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  if isNegative:
    return -value
  return value

proc multiplySmall(number: var seq[int], factor: int) =
  var carry = 0
  for groupIndex in 0..<number.len:
    let product = number[groupIndex] * factor + carry
    number[groupIndex] = product mod bigBase
    carry = product div bigBase
  while carry > 0:
    number.add carry mod bigBase
    carry = carry div bigBase

proc groupsToText(number: seq[int]): string =
  var text = ""
  var groupIndex = number.len - 1
  text.add $(number[groupIndex])
  while groupIndex > 0:
    groupIndex -= 1
    var part = $(number[groupIndex])
    while part.len < 9:
      part = "0" & part
    text.add part
  return text

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var queries: seq[int] = @[]
var largestQuery = 0
let caseCount = nextSignedInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let queryValue = nextSignedInt(inputData, scanPos)
  queries.add queryValue
  if queryValue > largestQuery:
    largestQuery = queryValue

var factorialTexts: seq[string] = @[]
factorialTexts.setLen(largestQuery + 1)
var factorialDigits: seq[int] = @[1]
factorialTexts[0] = "1"
for factor in 1..largestQuery:
  multiplySmall(factorialDigits, factor)
  factorialTexts[factor] = groupsToText(factorialDigits)

for caseIndex in 0..<caseCount:
  let queryValue = queries[caseIndex]
  if queryValue < 0:
    appendOutput("accept positive integer only!\n")
  elif queryValue <= 1:
    appendOutput($(queryValue) & "!=1\n")
  else:
    appendOutput($(queryValue) & "!=")
    for factor in 1..queryValue:
      if factor != 1:
        appendOutput("*")
      appendOutput($(factor))
    appendOutput("=")
    appendOutput(factorialTexts[queryValue])
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0

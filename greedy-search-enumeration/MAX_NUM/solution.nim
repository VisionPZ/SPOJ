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

proc nextDigitRun(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  let runStart = pos
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    pos += 1
  return data[runStart .. pos - 1]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let numberText = nextDigitRun(inputData, scanPos)
  var deleteCount = nextInt(inputData, scanPos)
  if deleteCount >= numberText.len:
    appendOutput("")
    outputBuffer.add '\n'
    continue
  var keptDigits = newSeq[char](numberText.len)
  var keptLength = 0
  for digitChar in numberText:
    while keptLength > 0 and deleteCount > 0 and keptDigits[keptLength - 1] < digitChar:
      keptLength -= 1
      deleteCount -= 1
    keptDigits[keptLength] = digitChar
    keptLength += 1
  var resultText = ""
  for keptIndex in 0 .. keptLength - deleteCount - 1:
    resultText.add keptDigits[keptIndex]
  appendOutput(resultText)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

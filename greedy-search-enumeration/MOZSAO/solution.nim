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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let repetitionCount = nextInt(inputData, scanPos)
  var words = ""
  for wordIndex in 1 .. repetitionCount:
    if wordIndex > 1:
      words.add ' '
    words.add "one"
  var marks = ""
  for markIndex in 1 .. repetitionCount:
    marks.add '!'
  appendOutput(words)
  appendOutput(marks)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

const cowSentenceCount = 5
const cowSentences = [
  "Cow is a domesticated animal.",
  "She helps mankind in many ways.",
  "Her milk is very healthy for babies.",
  "Cows usually eat green grass but they can survive on other things too.",
  "Blah blah blah."
]
const flushBlockBytes = 1 shl 17

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
  let startPos = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[startPos ..< pos]

proc nextLine(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let startPos = pos
  while pos < data.len and data[pos] != '\n':
    pos += 1
  var finishPos = pos
  if finishPos > startPos and data[finishPos - 1] == '\r':
    finishPos -= 1
  if pos < data.len:
    pos += 1
  return data[startPos ..< finishPos]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for _ in 0..<testCount:
  let topicName = nextToken(inputData, scanPos)
  let sentenceCount = nextInt(inputData, scanPos)
  var cheating = false
  for _ in 0..<sentenceCount:
    let sentence = nextLine(inputData, scanPos)
    if topicName != "cow":
      for k in 0..<cowSentenceCount:
        if sentence == cowSentences[k]:
          cheating = true
          break
  if cheating:
    appendOutput("Cheating\n")
  else:
    appendOutput("Not cheating\n")

stdout.write outputBuffer
outputBuffer.setLen 0

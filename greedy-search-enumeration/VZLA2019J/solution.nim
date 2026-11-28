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
for caseNumber in 1 .. caseCount:
  let cactusCount = nextInt(inputData, scanPos)
  var previousCactus = nextInt(inputData, scanPos)
  var canSurvive = true
  for cactusIndex in 1 .. cactusCount - 1:
    let currentCactus = nextInt(inputData, scanPos)
    if currentCactus - previousCactus == 1:
      canSurvive = false
    previousCactus = currentCactus
  appendOutput("Case #" & $caseNumber & ": ")
  if canSurvive:
    appendOutput("Survival!\n")
  else:
    appendOutput("Oh no!\n")
stdout.write outputBuffer
outputBuffer.setLen 0

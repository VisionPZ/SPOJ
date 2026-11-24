{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value

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

let caseCount = nextInt(inputData, scanPos)
for i in 0..<caseCount:
  let columnCount = nextInt(inputData, scanPos)
  var topReach = true
  var midReach = true
  var botReach = true
  var snakeReach = false
  for j in 0..<columnCount:
    let topType = nextInt(inputData, scanPos)
    let midType = nextInt(inputData, scanPos)
    let botType = nextInt(inputData, scanPos)
    let nextTop = (topReach and topType == 1) or
                  (midReach and topType == 2 and midType == 2) or
                  (botReach and topType == 2 and midType == 1 and botType == 2) or
                  (snakeReach and topType == 1 and midType == 2 and botType == 2)
    let nextMid = (topReach and topType == 2 and midType == 2) or
                  (midReach and midType == 1) or
                  (botReach and midType == 2 and botType == 2)
    let nextBot = (topReach and topType == 2 and midType == 1 and botType == 2) or
                  (midReach and midType == 2 and botType == 2) or
                  (botReach and botType == 1) or
                  (snakeReach and topType == 2 and midType == 2 and botType == 1)
    let nextSnake = (topReach and topType == 1 and midType == 2 and botType == 2) or
                    (botReach and topType == 2 and midType == 2 and botType == 1) or
                    (snakeReach and topType == 1 and midType == 1 and botType == 1)
    topReach = nextTop
    midReach = nextMid
    botReach = nextBot
    snakeReach = nextSnake
  if topReach or midReach or botReach:
    appendOutput("yes\n")
  else:
    appendOutput("no\n")

stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const countThreshold = 1000000000000000000

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

proc gcdInt(firstValue: int, secondValue: int): int =
  var larger = firstValue
  var smaller = secondValue
  while smaller != 0:
    let remainder = larger mod smaller
    larger = smaller
    smaller = remainder
  return larger

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let ignoredCaseLabel = nextInt(inputData, scanPos)
  let ponyCount = nextInt(inputData, scanPos)
  let firstNumber = nextInt(inputData, scanPos)
  var differenceGcd = 0
  for ponyIndex in 1 .. ponyCount - 1:
    let currentNumber = nextInt(inputData, scanPos)
    var difference = currentNumber - firstNumber
    if difference < 0:
      difference = -difference
    differenceGcd = gcdInt(differenceGcd, difference)
  appendOutput("Case #")
  appendOutput($caseIndex)
  appendOutput(": ")
  if ponyCount <= 1 or differenceGcd == 0 or differenceGcd > countThreshold:
    appendOutput("I can't count that high")
  else:
    appendOutput($differenceGcd)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

{.checks: off.}
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infinity = 1 shl 60

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let treasureCount = nextInt(inputData, scanPos)
  var position = newSeq[int](treasureCount + 1)
  var deadline = newSeq[int](treasureCount + 1)
  for k in 1..treasureCount:
    position[k] = nextInt(inputData, scanPos)
    deadline[k] = nextInt(inputData, scanPos)
  let span = position[treasureCount] - position[1]
  var allDeadlinesLoose = true
  for k in 1..treasureCount:
    if deadline[k] <= span:
      allDeadlinesLoose = false
      break
  var answer = 0
  if allDeadlinesLoose:
    answer = span
  elif treasureCount > 1:
    var prevLeft = newSeq[int](treasureCount + 2)
    var prevRight = newSeq[int](treasureCount + 2)
    var curLeft = newSeq[int](treasureCount + 2)
    var curRight = newSeq[int](treasureCount + 2)
    for k in 0..treasureCount + 1:
      prevLeft[k] = infinity
      prevRight[k] = infinity
      curLeft[k] = infinity
      curRight[k] = infinity
    prevLeft[1] = 0
    prevRight[1] = 0
    for rightIndex in 2..treasureCount:
      curLeft[rightIndex] = 0
      curRight[rightIndex] = 0
      var leftIndex = rightIndex - 1
      while leftIndex >= 1:
        var bestLeft = curLeft[leftIndex + 1] + position[leftIndex + 1] - position[leftIndex]
        let crossLeft = curRight[leftIndex + 1] + position[rightIndex] - position[leftIndex]
        if crossLeft < bestLeft: bestLeft = crossLeft
        if bestLeft >= deadline[leftIndex]: bestLeft = infinity
        curLeft[leftIndex] = bestLeft
        var bestRight = prevLeft[leftIndex] + position[rightIndex] - position[leftIndex]
        let crossRight = prevRight[leftIndex] + position[rightIndex] - position[rightIndex - 1]
        if crossRight < bestRight: bestRight = crossRight
        if bestRight >= deadline[rightIndex]: bestRight = infinity
        curRight[leftIndex] = bestRight
        leftIndex -= 1
      swap prevLeft, curLeft
      swap prevRight, curRight
    answer = min(prevLeft[1], prevRight[1])
  if answer >= infinity:
    appendOutput("No solution")
  else:
    appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

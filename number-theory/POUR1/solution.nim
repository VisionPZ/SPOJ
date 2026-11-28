const flushBlockBytes = 1 shl 17
const stepCeiling = 1 shl 20

proc gcdOf(leftValue, rightValue: int): int =
  var larger = leftValue
  var smaller = rightValue
  while smaller != 0:
    var remainder = larger mod smaller
    larger = smaller
    smaller = remainder
  return larger

proc stepsFor(firstCapacity, secondCapacity, target: int): int =
  var firstAmount = 0
  var secondAmount = 0
  var stepCount = 0
  while stepCount < stepCeiling:
    if firstAmount == target or secondAmount == target:
      return stepCount
    if firstAmount == 0:
      firstAmount = firstCapacity
    elif secondAmount == secondCapacity:
      secondAmount = 0
    else:
      var poured = firstAmount
      if secondCapacity - secondAmount < poured:
        poured = secondCapacity - secondAmount
      firstAmount = firstAmount - poured
      secondAmount = secondAmount + poured
    stepCount = stepCount + 1
  return -1

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  return value

var inputData: string
var lineBuffer: string
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add "\n"
var i = 0
var caseCount = nextInt(inputData, i)
var outputBuffer: string
for j in 1 .. caseCount:
  var firstCapacity = nextInt(inputData, i)
  var secondCapacity = nextInt(inputData, i)
  var target = nextInt(inputData, i)
  var answer: int
  if target > firstCapacity and target > secondCapacity:
    answer = -1
  elif target mod gcdOf(firstCapacity, secondCapacity) != 0:
    answer = -1
  else:
    var firstWay = stepsFor(firstCapacity, secondCapacity, target)
    var secondWay = stepsFor(secondCapacity, firstCapacity, target)
    if firstWay < 0 or secondWay < 0:
      answer = max(firstWay, secondWay)
    else:
      answer = min(firstWay, secondWay)
  outputBuffer.add $answer
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer

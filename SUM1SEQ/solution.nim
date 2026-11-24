const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9') and data[position] != '-':
    position += 1
  var signValue = 1
  if position < data.len and data[position] == '-':
    signValue = -1
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var isNegative = newSeq[bool](0)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let sequenceLength = nextInt(inputData, scanPos)
  let targetSum = nextInt(inputData, scanPos)
  let totalWeight = sequenceLength * (sequenceLength - 1) div 2
  let magnitudeSum = if targetSum < 0: -targetSum else: targetSum
  if (magnitudeSum + totalWeight) mod 2 != 0 or magnitudeSum > totalWeight:
    appendOutput("No\n\n")
    continue
  var remainingSum = (totalWeight - targetSum) div 2
  if isNegative.len <= sequenceLength:
    isNegative.setLen(sequenceLength + 1)
  var j = sequenceLength - 1
  while j >= 1:
    if j <= remainingSum:
      isNegative[j] = true
      remainingSum -= j
    else:
      isNegative[j] = false
    j -= 1
  appendOutput("0\n")
  var currentValue = 0
  for i in 1..<sequenceLength:
    let weightValue = sequenceLength - i
    if isNegative[weightValue]:
      currentValue -= 1
    else:
      currentValue += 1
    appendOutput($(currentValue))
    outputBuffer.add '\n'
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

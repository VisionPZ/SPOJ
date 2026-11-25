import algorithm

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

let testCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. testCount:
  let valueTotal = nextInt(inputData, scanPos)
  let stemUnit = nextInt(inputData, scanPos)
  var values = newSeq[int](valueTotal)
  for valueIndex in 0 .. valueTotal - 1:
    values[valueIndex] = nextInt(inputData, scanPos)
  values.sort(proc(leftValue, rightValue: int): int = leftValue - rightValue)

  let largestStem = values[valueTotal - 1] div stemUnit
  var stemWidth = 1
  var widthValue = largestStem
  while widthValue >= 10:
    stemWidth += 1
    widthValue = widthValue div 10

  appendOutput("Scenario #" & $(caseIndex) & ":\n")
  var position = 0
  while position < valueTotal:
    let currentStem = values[position] div stemUnit
    var digitCount = 1
    var digitValue = currentStem
    while digitValue >= 10:
      digitCount += 1
      digitValue = digitValue div 10
    for padIndex in 0 .. stemWidth - digitCount - 1:
      outputBuffer.add ' '
    appendOutput($(currentStem))
    outputBuffer.add ' '
    outputBuffer.add '|'
    outputBuffer.add ' '
    var firstLeaf = true
    while position < valueTotal and values[position] div stemUnit == currentStem:
      if not firstLeaf:
        outputBuffer.add ' '
      firstLeaf = false
      appendOutput($(values[position] mod stemUnit))
      position += 1
    outputBuffer.add '\n'
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

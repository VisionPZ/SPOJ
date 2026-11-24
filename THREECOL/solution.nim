const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxSpecLen = 10010

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
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var childLeft: array[maxSpecLen, int]
var childRight: array[maxSpecLen, int]
var childNeed: array[maxSpecLen, int]
var maxGreen: array[maxSpecLen, int]
var minGreen: array[maxSpecLen, int]
var maxOther: array[maxSpecLen, int]
var minOther: array[maxSpecLen, int]
var nodeStack: array[maxSpecLen, int]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  while scanPos < inputData.len and inputData[scanPos] < '0':
    scanPos += 1
  let wordStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] >= '0':
    scanPos += 1
  let wordLen = scanPos - wordStart

  var stackTop = -1
  for i in 0..<wordLen:
    let digit = int(inputData[wordStart + i]) - firstDigitValue
    childLeft[i] = -1
    childRight[i] = -1
    childNeed[i] = digit
    if stackTop >= 0:
      let parentIndex = nodeStack[stackTop]
      if childLeft[parentIndex] == -1:
        childLeft[parentIndex] = i
      else:
        childRight[parentIndex] = i
      childNeed[parentIndex] -= 1
      if childNeed[parentIndex] == 0:
        stackTop -= 1
    if digit > 0:
      stackTop += 1
      nodeStack[stackTop] = i

  for i in countdown(wordLen - 1, 0):
    let digit = int(inputData[wordStart + i]) - firstDigitValue
    if digit == 0:
      maxGreen[i] = 1
      minGreen[i] = 1
      maxOther[i] = 0
      minOther[i] = 0
    elif digit == 1:
      let childIndex = childLeft[i]
      maxGreen[i] = 1 + maxOther[childIndex]
      minGreen[i] = 1 + minOther[childIndex]
      maxOther[i] = max(maxGreen[childIndex], maxOther[childIndex])
      minOther[i] = min(minGreen[childIndex], minOther[childIndex])
    else:
      let leftIndex = childLeft[i]
      let rightIndex = childRight[i]
      maxGreen[i] = 1 + maxOther[leftIndex] + maxOther[rightIndex]
      minGreen[i] = 1 + minOther[leftIndex] + minOther[rightIndex]
      maxOther[i] = max(maxGreen[leftIndex] + maxOther[rightIndex],
                        maxOther[leftIndex] + maxGreen[rightIndex])
      minOther[i] = min(minGreen[leftIndex] + minOther[rightIndex],
                        minOther[leftIndex] + minGreen[rightIndex])

  let answerMax = max(maxGreen[0], maxOther[0])
  let answerMin = min(minGreen[0], minOther[0])
  appendOutput($(answerMax) & " " & $(answerMin) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0

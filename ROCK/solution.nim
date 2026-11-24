const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const negInfinite = -1000000000
const maxStickLength = 200
const treeCapacity = 2 * maxStickLength + 3

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var fenwick: array[treeCapacity, int]
var fenwickSize = 0

proc fenwickUpdate(index: int, value: int) =
  var j = index
  while j <= fenwickSize:
    if value > fenwick[j]:
      fenwick[j] = value
    j += j and (-j)

proc fenwickPrefixMax(index: int): int =
  result = negInfinite
  var j = index
  while j > 0:
    if fenwick[j] > result:
      result = fenwick[j]
    j -= j and (-j)

let caseCount = nextInt(inputData, scanPos)
for k in 0..<caseCount:
  let stickLength = nextInt(inputData, scanPos)
  while scanPos < inputData.len and inputData[scanPos] != '0' and inputData[scanPos] != '1':
    scanPos += 1
  fenwickSize = 2 * stickLength + 2
  for j in 0..<treeCapacity:
    fenwick[j] = negInfinite
  fenwickUpdate(stickLength + 1, 0)
  var prefixScore = 0
  var bestSold = 0
  for i in 1..stickLength:
    if inputData[scanPos] == '1':
      prefixScore += 1
    else:
      prefixScore -= 1
    scanPos += 1
    let scoreIndex = prefixScore + stickLength + 1
    let candidate = i + fenwickPrefixMax(scoreIndex - 1)
    if candidate > bestSold:
      bestSold = candidate
    fenwickUpdate(scoreIndex, bestSold - i)
  appendOutput($(bestSold))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

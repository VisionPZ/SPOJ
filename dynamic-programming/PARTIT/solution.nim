const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxSum = 220
const maxParts = 10

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int64 =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value: int64 = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int64(int(data[i]) - firstDigitValue)
    i += 1
  return value

var partitionWays: array[0..maxSum, array[0..maxParts, int64]]
for i in 0..maxSum:
  for j in 0..maxParts:
    if i == 0:
      partitionWays[i][j] = 1
    elif j == 0:
      partitionWays[i][j] = 0
    else:
      partitionWays[i][j] = partitionWays[i][j - 1]
      if i >= j:
        partitionWays[i][j] += partitionWays[i - j][j]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var chosenParts: array[0..maxParts - 1, int]

let caseCount = int(nextInt(inputData, i))
for j in 0..<caseCount:
  let totalSum = int(nextInt(inputData, i))
  let partCount = int(nextInt(inputData, i))
  var rank = nextInt(inputData, i)
  var remainingSum = totalSum
  var partsLeft = partCount
  var minValue = 1
  var k = 0
  while partsLeft > 0:
    if partsLeft == 1:
      chosenParts[k] = remainingSum
      k += 1
      partsLeft = 0
      break
    var candidate = minValue
    var picked = false
    while candidate * partsLeft <= remainingSum:
      let shiftedSum = remainingSum - partsLeft * candidate
      let blockSize = partitionWays[shiftedSum][partsLeft - 1]
      if rank > blockSize:
        rank -= blockSize
        candidate += 1
      else:
        chosenParts[k] = candidate
        k += 1
        remainingSum -= candidate
        partsLeft -= 1
        minValue = candidate
        picked = true
        break
    if not picked:
      chosenParts[k] = remainingSum
      k += 1
      partsLeft = 0
  for l in 0..<partCount:
    if l > 0:
      outputBuffer.add ' '
    appendOutput($(chosenParts[l]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

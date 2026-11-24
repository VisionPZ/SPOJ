const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxSum = 220
const maxParts = 10

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int64 =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value: int64 = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int64(int(data[position]) - firstDigitValue)
    position += 1
  return value

var partitionWays: array[0..maxSum, array[0..maxParts, int64]]
for sumValue in 0..maxSum:
  for partLimit in 0..maxParts:
    if sumValue == 0:
      partitionWays[sumValue][partLimit] = 1
    elif partLimit == 0:
      partitionWays[sumValue][partLimit] = 0
    else:
      partitionWays[sumValue][partLimit] = partitionWays[sumValue][partLimit - 1]
      if sumValue >= partLimit:
        partitionWays[sumValue][partLimit] += partitionWays[sumValue - partLimit][partLimit]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var chosenParts: array[0..maxParts - 1, int]

let caseCount = int(nextInt(inputData, scanPos))
for caseIndex in 0..<caseCount:
  let totalSum = int(nextInt(inputData, scanPos))
  let partCount = int(nextInt(inputData, scanPos))
  var rank = nextInt(inputData, scanPos)
  var remainingSum = totalSum
  var partsLeft = partCount
  var minValue = 1
  var chosenIndex = 0
  while partsLeft > 0:
    if partsLeft == 1:
      chosenParts[chosenIndex] = remainingSum
      chosenIndex += 1
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
        chosenParts[chosenIndex] = candidate
        chosenIndex += 1
        remainingSum -= candidate
        partsLeft -= 1
        minValue = candidate
        picked = true
        break
    if not picked:
      chosenParts[chosenIndex] = remainingSum
      chosenIndex += 1
      partsLeft = 0
  for partIndex in 0..<partCount:
    if partIndex > 0:
      outputBuffer.add ' '
    appendOutput($(chosenParts[partIndex]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

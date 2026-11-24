{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

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

proc flushOutput() =
  stdout.write outputBuffer
  outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    flushOutput()

proc appendPair(leftTown, rightTown: int) =
  outputBuffer.add $(leftTown)
  outputBuffer.add ' '
  outputBuffer.add $(rightTown)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    flushOutput()

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let nodeCount = nextInt(inputData, scanPos)
  var distances = newSeq[int](nodeCount * nodeCount)
  for i in 0..<nodeCount:
    for j in 0..<nodeCount:
      distances[i * nodeCount + j] = nextInt(inputData, scanPos)
  if caseIndex > 0:
    appendOutput "\n"
  for i in 0..<nodeCount:
    for j in i + 1..<nodeCount:
      let directDistance = distances[i * nodeCount + j]
      var hasIntermediate = false
      for k in 0..<nodeCount:
        if k == i or k == j:
          continue
        if distances[i * nodeCount + k] + distances[k * nodeCount + j] == directDistance:
          hasIntermediate = true
          break
      if not hasIntermediate:
        appendPair i + 1, j + 1

flushOutput()

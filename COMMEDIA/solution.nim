const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const solvableMessage = "Puzzle can be solved."
const unsolvableMessage = "Puzzle is unsolvable."

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

var fenwickTree: seq[int]

proc addValue(treeIndex: int, delta: int) =
  var index = treeIndex
  while index < fenwickTree.len:
    fenwickTree[index] += delta
    index += index and -index

proc prefixSum(treeIndex: int): int =
  var total = 0
  var index = treeIndex
  while index > 0:
    total += fenwickTree[index]
    index -= index and -index
  return total

proc permutationParity(slotCount: int, blankValue: int, blankIndex: var int): int =
  fenwickTree = newSeq[int](slotCount + 1)
  var parity = 0
  for slotIndex in 0..<slotCount:
    let tileValue = nextInt(inputData, scanPos)
    if tileValue == 0:
      blankIndex = slotIndex
    let sequenceValue = if tileValue == 0: blankValue else: tileValue
    parity = (parity + (slotIndex - prefixSum(sequenceValue))) and 1
    addValue(sequenceValue, 1)
  return parity

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1..caseCount:
  let sideLength = nextInt(inputData, scanPos)
  let slotCount = sideLength * sideLength * sideLength
  var blankIndex = 0
  let parity = permutationParity(slotCount, slotCount, blankIndex)
  let coordinateX = blankIndex mod sideLength
  let coordinateY = (blankIndex div sideLength) mod sideLength
  let coordinateZ = blankIndex div (sideLength * sideLength)
  let blankCoordinateParity = (coordinateX + coordinateY + coordinateZ) and 1
  let solvedCoordinateParity = (3 * (sideLength - 1)) and 1
  if ((parity + blankCoordinateParity) and 1) == solvedCoordinateParity:
    appendOutput(solvableMessage)
  else:
    appendOutput(unsolvableMessage)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

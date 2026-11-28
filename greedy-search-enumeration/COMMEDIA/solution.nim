const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const solvableMessage = "Puzzle can be solved."
const unsolvableMessage = "Puzzle is unsolvable."

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

var fenwickTree: seq[int]

proc addValue(j: int, delta: int) =
  var k = j
  while k < fenwickTree.len:
    fenwickTree[k] += delta
    k += k and -k

proc prefixSum(j: int): int =
  var total = 0
  var k = j
  while k > 0:
    total += fenwickTree[k]
    k -= k and -k
  return total

proc permutationParity(slotCount: int, blankValue: int, k: var int): int =
  fenwickTree = newSeq[int](slotCount + 1)
  var parity = 0
  for j in 0..<slotCount:
    let tileValue = nextInt(inputData, i)
    if tileValue == 0:
      k = j
    let sequenceValue = if tileValue == 0: blankValue else: tileValue
    parity = (parity + (j - prefixSum(sequenceValue))) and 1
    addValue(sequenceValue, 1)
  return parity

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, i)
for j in 1..caseCount:
  let sideLength = nextInt(inputData, i)
  let slotCount = sideLength * sideLength * sideLength
  var k = 0
  let parity = permutationParity(slotCount, slotCount, k)
  let coordinateX = k mod sideLength
  let coordinateY = (k div sideLength) mod sideLength
  let coordinateZ = k div (sideLength * sideLength)
  let blankCoordinateParity = (coordinateX + coordinateY + coordinateZ) and 1
  let solvedCoordinateParity = (3 * (sideLength - 1)) and 1
  if ((parity + blankCoordinateParity) and 1) == solvedCoordinateParity:
    appendOutput(solvableMessage)
  else:
    appendOutput(unsolvableMessage)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

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

proc multiplyMatrix(left: seq[int64], right: seq[int64], size: int, modulus: int64): seq[int64] =
  var result = newSeq[int64](size * size)
  for rowIndex in 0 .. size - 1:
    for columnIndex in 0 .. size - 1:
      var total: int64 = 0
      for innerIndex in 0 .. size - 1:
        total = (total + left[rowIndex * size + innerIndex] * right[innerIndex * size + columnIndex]) mod modulus
      result[rowIndex * size + columnIndex] = total
  return result

proc advanceVector(state: var seq[int64], transition: seq[int64], size: int, modulus: int64) =
  var updated = newSeq[int64](size)
  for columnIndex in 0 .. size - 1:
    var total: int64 = 0
    for rowIndex in 0 .. size - 1:
      total = (total + state[rowIndex] * transition[rowIndex * size + columnIndex]) mod modulus
    updated[columnIndex] = total
  state = updated

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let order = nextInt(inputData, scanPos)
  var initialValues = newSeq[int64](order)
  for valueIndex in 0 .. order - 1:
    initialValues[valueIndex] = int64(nextInt(inputData, scanPos))
  var coefficients = newSeq[int64](order)
  for valueIndex in 0 .. order - 1:
    coefficients[valueIndex] = int64(nextInt(inputData, scanPos))
  let lowerIndex = int64(nextInt(inputData, scanPos))
  let upperIndex = int64(nextInt(inputData, scanPos))
  let modulus = int64(nextInt(inputData, scanPos))
  let size = order + 1
  var transition = newSeq[int64](size * size)
  for sourceIndex in 0 .. order - 1:
    transition[sourceIndex * size] = coefficients[sourceIndex] mod modulus
    transition[sourceIndex * size + order] = coefficients[sourceIndex] mod modulus
  for targetIndex in 1 .. order - 1:
    transition[(targetIndex - 1) * size + targetIndex] = 1
  transition[order * size + order] = 1
  var stateVector = newSeq[int64](size)
  var runningTotal: int64 = 0
  for valueIndex in 0 .. order - 1:
    runningTotal = (runningTotal + initialValues[valueIndex]) mod modulus
    stateVector[order - 1 - valueIndex] = initialValues[valueIndex] mod modulus
  stateVector[order] = runningTotal
  var upperPower = upperIndex - int64(order)
  var lowerPower = int64(0)
  var lowerState = stateVector
  if lowerIndex - 1 > int64(order):
    lowerPower = lowerIndex - 1 - int64(order)
  else:
    var prefixTotal: int64 = 0
    for valueIndex in 0 .. int(lowerIndex) - 2:
      prefixTotal = (prefixTotal + initialValues[valueIndex]) mod modulus
    lowerState[order] = prefixTotal
  while upperPower > 0 or lowerPower > 0:
    if (upperPower and 1) == 1:
      advanceVector(stateVector, transition, size, modulus)
    if (lowerPower and 1) == 1:
      advanceVector(lowerState, transition, size, modulus)
    transition = multiplyMatrix(transition, transition, size, modulus)
    upperPower = upperPower shr 1
    lowerPower = lowerPower shr 1
  var answer = stateVector[order] - lowerState[order]
  if answer < 0:
    answer = answer + modulus
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

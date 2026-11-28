const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const sequenceModulus: int64 = 1000000000
const maxOrder = 10

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value

proc squareTransition(transition: array[maxOrder, array[maxOrder, int64]], order: int): array[maxOrder, array[maxOrder, int64]] =
  for row in 0 .. order - 1:
    for col in 0 .. order - 1:
      var sum: int64 = 0
      for pivot in 0 .. order - 1:
        sum = (sum + transition[row][pivot] * transition[pivot][col]) mod sequenceModulus
      result[row][col] = sum

proc applyTransition(transition: array[maxOrder, array[maxOrder, int64]], state: array[maxOrder, int64], order: int): array[maxOrder, int64] =
  for row in 0 .. order - 1:
    var sum: int64 = 0
    for col in 0 .. order - 1:
      sum = (sum + transition[row][col] * state[col]) mod sequenceModulus
    result[row] = sum

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = int(nextInt(inputData, scanPos))
var outputBuffer = ""

for _ in 0 .. caseCount - 1:
  let order = int(nextInt(inputData, scanPos))
  var seedValues: array[maxOrder, int64]
  for idx in 0 .. order - 1:
    seedValues[idx] = nextInt(inputData, scanPos) mod sequenceModulus
  var coefficients: array[maxOrder, int64]
  for idx in 0 .. order - 1:
    coefficients[idx] = nextInt(inputData, scanPos) mod sequenceModulus
  let targetIndex = nextInt(inputData, scanPos)
  var answer: int64
  if targetIndex <= int64(order):
    answer = seedValues[int(targetIndex) - 1]
  else:
    var state: array[maxOrder, int64]
    for idx in 0 .. order - 1:
      state[idx] = seedValues[order - 1 - idx]
    var transition: array[maxOrder, array[maxOrder, int64]]
    for col in 0 .. order - 1:
      transition[0][col] = coefficients[col]
    for idx in 1 .. order - 1:
      transition[idx][idx - 1] = 1
    var accumulator = state
    var exponent = targetIndex - int64(order)
    while exponent > 0:
      if (exponent and 1) == 1:
        accumulator = applyTransition(transition, accumulator, order)
      transition = squareTransition(transition, order)
      exponent = exponent shr 1
    answer = accumulator[0]
  outputBuffer.add $answer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0

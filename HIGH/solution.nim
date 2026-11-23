const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxCities = 12
const firstModulus: int64 = 1000000007
const secondModulus: int64 = 1000000009

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

proc modPower(baseValue: int64, exponentValue: int64, modulus: int64): int64 =
  var baseRemainder = baseValue mod modulus
  if baseRemainder < 0:
    baseRemainder += modulus
  var result: int64 = 1
  var walker = exponentValue
  while walker > 0:
    if (walker and 1) == 1:
      result = result * baseRemainder mod modulus
    baseRemainder = baseRemainder * baseRemainder mod modulus
    walker = walker shr 1
  return result

proc determinantModulo(matrix: array[maxCities, array[maxCities, int64]],
                       size: int, modulus: int64): int64 =
  var work: array[maxCities, array[maxCities, int64]]
  for row in 0..<size:
    for column in 0..<size:
      work[row][column] = matrix[row][column] mod modulus
      if work[row][column] < 0:
        work[row][column] += modulus
  var result: int64 = 1
  for pivot in 0..<size:
    var pivotRow = pivot
    while pivotRow < size and work[pivotRow][pivot] == 0:
      pivotRow += 1
    if pivotRow == size:
      return 0
    if pivotRow != pivot:
      for column in 0..<size:
        swap work[pivot][column], work[pivotRow][column]
      result = modulus - result
    let pivotValue = work[pivot][pivot]
    result = result * pivotValue mod modulus
    let inversePivot = modPower(pivotValue, modulus - 2, modulus)
    for row in pivot + 1..<size:
      if work[row][pivot] == 0:
        continue
      let factor = work[row][pivot] * inversePivot mod modulus
      for column in pivot..<size:
        work[row][column] = (work[row][column] - factor * work[pivot][column]) mod modulus
        if work[row][column] < 0:
          work[row][column] += modulus
  return result

proc spanningTreeCount(matrix: array[maxCities, array[maxCities, int64]],
                       size: int): int64 =
  let firstRemainder = determinantModulo(matrix, size, firstModulus)
  let secondRemainder = determinantModulo(matrix, size, secondModulus)
  let difference = (secondRemainder - firstRemainder + secondModulus) mod secondModulus
  let inverseFirst = modPower(firstModulus mod secondModulus,
                              secondModulus - 2, secondModulus)
  let multiplier = difference * inverseFirst mod secondModulus
  return firstRemainder + firstModulus * multiplier

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let cityCount = nextInt(inputData, scanPos)
  let connectionCount = nextInt(inputData, scanPos)
  var matrix: array[maxCities, array[maxCities, int64]]
  for row in 0..<cityCount - 1:
    for column in 0..<cityCount - 1:
      matrix[row][column] = 0
  for connectionIndex in 0..<connectionCount:
    let firstCity = nextInt(inputData, scanPos) - 1
    let secondCity = nextInt(inputData, scanPos) - 1
    if firstCity < cityCount - 1:
      matrix[firstCity][firstCity] += 1
      if secondCity < cityCount - 1:
        matrix[firstCity][secondCity] -= 1
    if secondCity < cityCount - 1:
      matrix[secondCity][secondCity] += 1
      if firstCity < cityCount - 1:
        matrix[secondCity][firstCity] -= 1
  if cityCount == 1:
    appendOutput("1")
  else:
    appendOutput($spanningTreeCount(matrix, cityCount - 1))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

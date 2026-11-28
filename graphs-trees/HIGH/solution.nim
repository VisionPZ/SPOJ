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

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
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
  for i in 0..<size:
    for j in 0..<size:
      work[i][j] = matrix[i][j] mod modulus
      if work[i][j] < 0:
        work[i][j] += modulus
  var result: int64 = 1
  for i in 0..<size:
    var j = i
    while j < size and work[j][i] == 0:
      j += 1
    if j == size:
      return 0
    if j != i:
      for k in 0..<size:
        swap work[i][k], work[j][k]
      result = modulus - result
    let pivotValue = work[i][i]
    result = result * pivotValue mod modulus
    let inversePivot = modPower(pivotValue, modulus - 2, modulus)
    for k in i + 1..<size:
      if work[k][i] == 0:
        continue
      let factor = work[k][i] * inversePivot mod modulus
      for l in i..<size:
        work[k][l] = (work[k][l] - factor * work[i][l]) mod modulus
        if work[k][l] < 0:
          work[k][l] += modulus
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

let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  let cityCount = nextInt(inputData, i)
  let connectionCount = nextInt(inputData, i)
  var matrix: array[maxCities, array[maxCities, int64]]
  for k in 0..<cityCount - 1:
    for l in 0..<cityCount - 1:
      matrix[k][l] = 0
  for k in 0..<connectionCount:
    let firstCity = nextInt(inputData, i) - 1
    let secondCity = nextInt(inputData, i) - 1
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

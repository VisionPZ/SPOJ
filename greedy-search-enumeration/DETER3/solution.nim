const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc modInverse(value: int64, modulus: int64): int64 =
  var oldRemainder = value mod modulus
  if oldRemainder < 0:
    oldRemainder += modulus
  var remainder = modulus
  var oldCoefficient: int64 = 1
  var coefficient: int64 = 0
  while remainder != 0:
    let quotient = oldRemainder div remainder
    let nextRemainder = oldRemainder - quotient * remainder
    oldRemainder = remainder
    remainder = nextRemainder
    let nextCoefficient = oldCoefficient - quotient * coefficient
    oldCoefficient = coefficient
    coefficient = nextCoefficient
  var inverse = oldCoefficient mod modulus
  if inverse < 0:
    inverse += modulus
  return inverse

proc valuationOf(value: int64, prime: int64): int =
  if value == 0:
    return high(int)
  var remaining = value
  var power = 0
  while remaining mod prime == 0:
    remaining = remaining div prime
    power += 1
  return power

proc primePowerOf(prime: int64, exponent: int): int64 =
  var power: int64 = 1
  for step in 1 .. exponent:
    power = power * prime
  return power

proc determinantForPrimePower(matrix: seq[int64], size: int,
                              prime: int64, exponent: int): int64 =
  let modulus = primePowerOf(prime, exponent)
  var work = newSeq[int64](size * size)
  for index in 0 .. size * size - 1:
    var normalized = matrix[index] mod modulus
    if normalized < 0:
      normalized += modulus
    work[index] = normalized
  var signMultiplier: int64 = 1
  var accumulated: int64 = 1
  for column in 0 .. size - 1:
    var bestRow = column
    var bestValue = work[column * size + column]
    var bestValuation = valuationOf(bestValue, prime)
    for row in column + 1 .. size - 1:
      let candidate = work[row * size + column]
      let candidateValuation = valuationOf(candidate, prime)
      if candidateValuation < bestValuation:
        bestValuation = candidateValuation
        bestRow = row
        bestValue = candidate
        if bestValuation == 0:
          break
    if bestValue == 0 or bestValuation >= exponent:
      return 0
    if bestRow != column:
      for columnIndex in 0 .. size - 1:
        swap work[column * size + columnIndex], work[bestRow * size + columnIndex]
      signMultiplier = -signMultiplier
    let pivotValue = work[column * size + column]
    accumulated = (accumulated * pivotValue) mod modulus
    let pivotPower = primePowerOf(prime, bestValuation)
    let unitPart = pivotValue div pivotPower
    let inverseUnit = modInverse(unitPart, modulus)
    for row in column + 1 .. size - 1:
      let entryValue = work[row * size + column]
      if entryValue == 0:
        continue
      let scaledFactor = ((entryValue div pivotPower) * inverseUnit) mod modulus
      for columnIndex in column + 1 .. size - 1:
        let subtrahend = (scaledFactor * work[column * size + columnIndex]) mod modulus
        var updated = work[row * size + columnIndex] - subtrahend
        if updated < 0:
          updated += modulus
        work[row * size + columnIndex] = updated
      work[row * size + column] = 0
  let signedProduct = accumulated * signMultiplier
  var answer = signedProduct mod modulus
  if answer < 0:
    answer += modulus
  return answer

proc determinantModulo(matrix: seq[int64], size: int,
                       modulusValue: int64): int64 =
  if modulusValue == 1:
    return 0
  var remainingModulus = modulusValue
  var combinedResidue: int64 = 0
  var combinedModulus: int64 = 1
  var prime: int64 = 2
  while prime * prime <= remainingModulus:
    if remainingModulus mod prime == 0:
      var exponent = 0
      var primePower: int64 = 1
      while remainingModulus mod prime == 0:
        remainingModulus = remainingModulus div prime
        exponent += 1
        primePower = primePower * prime
      let residue = determinantForPrimePower(matrix, size, prime, exponent)
      if combinedModulus == 1:
        combinedResidue = residue mod primePower
        combinedModulus = primePower
      else:
        let inverseModulus = modInverse(combinedModulus mod primePower, primePower)
        let difference = ((residue - combinedResidue) mod primePower + primePower) mod primePower
        let step = (difference * inverseModulus) mod primePower
        combinedResidue = (combinedResidue + combinedModulus * step) mod (combinedModulus * primePower)
        combinedModulus = combinedModulus * primePower
    prime += 1
  if remainingModulus > 1:
    let residue = determinantForPrimePower(matrix, size, remainingModulus, 1)
    if combinedModulus == 1:
      combinedResidue = residue mod remainingModulus
      combinedModulus = remainingModulus
    else:
      let inverseModulus = modInverse(combinedModulus mod remainingModulus, remainingModulus)
      let difference = ((residue - combinedResidue) mod remainingModulus + remainingModulus) mod remainingModulus
      let step = (difference * inverseModulus) mod remainingModulus
      combinedResidue = (combinedResidue + combinedModulus * step) mod (combinedModulus * remainingModulus)
      combinedModulus = combinedModulus * remainingModulus
  return combinedResidue mod modulusValue

var allValues = newSeq[int64]()
var tokenPos = 0
while tokenPos < inputData.len:
  let current = inputData[tokenPos]
  if (current >= '0' and current <= '9') or current == '-':
    allValues.add nextInt(inputData, tokenPos)
  else:
    tokenPos += 1

var valuePos = 0
while valuePos < allValues.len:
  let matrixSize = int(allValues[valuePos])
  valuePos += 1
  let modulusValue = allValues[valuePos]
  valuePos += 1
  var matrix = newSeq[int64](matrixSize * matrixSize)
  for index in 0 .. matrixSize * matrixSize - 1:
    matrix[index] = allValues[valuePos]
    valuePos += 1
  let answer = determinantModulo(matrix, matrixSize, modulusValue)
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

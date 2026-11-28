const flushBlockBytes = 1 shl 17
const maxFactorBase = 46341

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

proc powerInt(base: int64, exponent: int): int64 =
  result = 1
  for stepIndex in 1 .. exponent:
    result = result * base

proc primeValuation(value: int64, prime: int64): int =
  if value == 0:
    return 1000000000
  var current = value
  while current mod prime == 0:
    current = current div prime
    result += 1

proc extendedGcd(firstValue: int64, secondValue: int64, firstCoeff: var int64, secondCoeff: var int64): int64 =
  if secondValue == 0:
    firstCoeff = 1
    secondCoeff = 0
    return firstValue
  var previousCoeff: int64 = 0
  var otherCoeff: int64 = 0
  let divisor = extendedGcd(secondValue, firstValue mod secondValue, previousCoeff, otherCoeff)
  firstCoeff = otherCoeff
  secondCoeff = previousCoeff - (firstValue div secondValue) * otherCoeff
  return divisor

proc inverseMod(value: int64, modulus: int64): int64 =
  var firstCoeff: int64 = 0
  var secondCoeff: int64 = 0
  discard extendedGcd(value, modulus, firstCoeff, secondCoeff)
  result = firstCoeff mod modulus
  if result < 0:
    result += modulus

var primes = newSeq[int](0)
var compositeFlags = newSeq[bool](maxFactorBase + 1)
for candidate in 2 .. maxFactorBase:
  if not compositeFlags[candidate]:
    primes.add candidate
    var multiple = candidate * 2
    while multiple <= maxFactorBase:
      compositeFlags[multiple] = true
      multiple += candidate

proc factorModulus(modulus: int64, factors: var seq[int64], exponents: var seq[int]) =
  var remaining = modulus
  for primeValue in primes:
    if int64(primeValue) * int64(primeValue) > remaining:
      break
    if remaining mod int64(primeValue) == 0:
      var exponent = 0
      while remaining mod int64(primeValue) == 0:
        remaining = remaining div int64(primeValue)
        exponent += 1
      factors.add int64(primeValue)
      exponents.add exponent
  if remaining > 1:
    factors.add remaining
    exponents.add 1

proc solveForPrimePower(terms: seq[int64], order: int, prime: int64, exponent: int): int64 =
  let primePower = powerInt(prime, exponent)
  var equations = newSeq[seq[int64]](order)
  for rowIndex in 0 .. order - 1:
    equations[rowIndex] = newSeq[int64](order + 1)
    let equationIndex = order + rowIndex
    for columnIndex in 0 .. order - 1:
      equations[rowIndex][columnIndex] = terms[equationIndex - 1 - columnIndex] mod primePower
    equations[rowIndex][order] = terms[equationIndex] mod primePower
  var pivotColumns = newSeq[int](order)
  for columnIndex in 0 .. order - 1:
    pivotColumns[columnIndex] = -1
  var pivotRow = 0
  for columnIndex in 0 .. order - 1:
    var bestRow = -1
    var bestValuation = 1000000000
    for rowIndex in pivotRow .. order - 1:
      let valuation = primeValuation(equations[rowIndex][columnIndex], prime)
      if valuation < bestValuation:
        bestValuation = valuation
        bestRow = rowIndex
    if bestRow < 0 or bestValuation >= exponent:
      continue
    swap equations[bestRow], equations[pivotRow]
    let divisor = powerInt(prime, bestValuation)
    let reducedModulus = primePower div divisor
    let reducedPivot = (equations[pivotRow][columnIndex] div divisor) mod reducedModulus
    let pivotInverse = inverseMod(reducedPivot, reducedModulus)
    for rowIndex in pivotRow + 1 .. order - 1:
      let reducedEntry = (equations[rowIndex][columnIndex] div divisor) mod reducedModulus
      let fullFactor = reducedEntry * pivotInverse mod reducedModulus
      for updateColumn in columnIndex .. order:
        var updated = (equations[rowIndex][updateColumn] - fullFactor * equations[pivotRow][updateColumn]) mod primePower
        if updated < 0:
          updated += primePower
        equations[rowIndex][updateColumn] = updated
    pivotColumns[pivotRow] = columnIndex
    pivotRow += 1
  var coefficients = newSeq[int64](order)
  var rowIndex = pivotRow
  while rowIndex > 0:
    rowIndex -= 1
    let columnIndex = pivotColumns[rowIndex]
    let valuation = primeValuation(equations[rowIndex][columnIndex], prime)
    let divisor = powerInt(prime, valuation)
    let reducedModulus = primePower div divisor
    var rightSide = equations[rowIndex][order]
    for laterColumn in columnIndex + 1 .. order - 1:
      rightSide = (rightSide - equations[rowIndex][laterColumn] * coefficients[laterColumn]) mod primePower
      if rightSide < 0:
        rightSide += primePower
    let reducedRightSide = (rightSide div divisor) mod reducedModulus
    let reducedPivot = (equations[rowIndex][columnIndex] div divisor) mod reducedModulus
    coefficients[columnIndex] = reducedRightSide * inverseMod(reducedPivot, reducedModulus) mod reducedModulus
  var resultValue: int64 = 0
  for offset in 1 .. order:
    resultValue = (resultValue + coefficients[offset - 1] * terms[2 * order - offset]) mod primePower
  return resultValue

let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let order = nextInt(inputData, scanPos)
  let modulus = int64(nextInt(inputData, scanPos))
  var terms = newSeq[int64](2 * order)
  for termIndex in 0 .. 2 * order - 1:
    terms[termIndex] = int64(nextInt(inputData, scanPos)) mod modulus
  var factors = newSeq[int64](0)
  var exponents = newSeq[int](0)
  factorModulus(modulus, factors, exponents)
  var combined: int64 = 0
  var currentModulus: int64 = 1
  for factorIndex in 0 .. factors.len - 1:
    let primePower = powerInt(factors[factorIndex], exponents[factorIndex])
    let residue = solveForPrimePower(terms, order, factors[factorIndex], exponents[factorIndex])
    let inverse = inverseMod(currentModulus mod primePower, primePower)
    var difference = (residue - combined) mod primePower
    if difference < 0:
      difference += primePower
    let adjustment = difference * inverse mod primePower
    combined = (combined + currentModulus * adjustment) mod (currentModulus * primePower)
    currentModulus = currentModulus * primePower
  appendOutput($combined)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

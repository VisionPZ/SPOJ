const flushBlockBytes = 1 shl 17
const modulus = 1000000007
const maxPrimeCount = 500
const maxPrimeDegree = 500
const primeLimit = 4000
const tableStride = maxPrimeDegree + 1

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

var isComposite = newSeq[bool](primeLimit + 1)
var primeList = newSeq[int](maxPrimeCount)
var foundPrimes = 0
for candidate in 2 .. primeLimit:
  if not isComposite[candidate]:
    primeList[foundPrimes] = candidate
    foundPrimes += 1
    if foundPrimes == maxPrimeCount:
      break
    var multiple = candidate * candidate
    while multiple <= primeLimit:
      isComposite[multiple] = true
      multiple += candidate

var coefficientTable = newSeq[int]((maxPrimeCount + 1) * tableStride)
var baseFactors = newSeq[int](maxPrimeCount + 1)
coefficientTable[0] = 1
baseFactors[0] = 1
for primeIndex in 1 .. maxPrimeCount:
  let currentPrime = primeList[primeIndex - 1]
  baseFactors[primeIndex] = int(int64(baseFactors[primeIndex - 1]) *
      int64(currentPrime - 1) mod int64(modulus))
  let previousRow = (primeIndex - 1) * tableStride
  let currentRow = primeIndex * tableStride
  coefficientTable[currentRow] = 1
  for extraExponent in 1 .. maxPrimeDegree:
    let carry = int64(currentPrime) * int64(coefficientTable[currentRow + extraExponent - 1])
    let total = int64(coefficientTable[previousRow + extraExponent]) + carry
    coefficientTable[currentRow + extraExponent] = int(total mod int64(modulus))

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let primeDegree = nextInt(inputData, scanPos)
  let primeFactorCount = nextInt(inputData, scanPos)
  let extraExponent = primeDegree - primeFactorCount
  let coefficient = coefficientTable[primeFactorCount * tableStride + extraExponent]
  let answer = int(int64(baseFactors[primeFactorCount]) * int64(coefficient) mod int64(modulus))
  appendOutput("Case " & $caseIndex & ": " & $answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const primeModulus = 1000000007

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

proc powerMod(baseValue: int64, exponentValue: int64): int64 =
  var powerResult: int64 = 1
  var base = baseValue mod primeModulus
  var exponent = exponentValue
  while exponent > 0:
    if exponent mod 2 == 1:
      powerResult = (powerResult * base) mod primeModulus
    base = (base * base) mod primeModulus
    exponent = exponent div 2
  return powerResult

let limit = nextInt(inputData, scanPos)
var mobius = newSeq[int](limit + 1)
var composite = newSeq[bool](limit + 1)
var primes = newSeq[int](0)
if limit >= 1:
  mobius[1] = 1
for value in 2 .. limit:
  if not composite[value]:
    primes.add value
    mobius[value] = -1
  for primeIndex in 0 .. primes.len - 1:
    let prime = primes[primeIndex]
    if value * prime > limit:
      break
    composite[value * prime] = true
    if value mod prime == 0:
      mobius[value * prime] = 0
      break
    mobius[value * prime] = -mobius[value]
var exponents = newSeq[int64](limit + 1)
for divisor in 1 .. limit:
  if mobius[divisor] != 0:
    let quotient = limit div divisor
    let triangular = (int64(quotient) * int64(quotient + 1)) div 2
    let term = int64(mobius[divisor]) * int64(divisor) * triangular
    var multiple = divisor
    while multiple <= limit:
      exponents[multiple] = exponents[multiple] + term
      multiple = multiple + divisor
var result: int64 = 1
for baseValue in 2 .. limit:
  if exponents[baseValue] > 0:
    result = (result * powerMod(int64(baseValue), exponents[baseValue])) mod primeModulus
appendOutput($result)
appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0

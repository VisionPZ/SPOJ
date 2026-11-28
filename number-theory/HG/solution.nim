import tables

const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const digitLimit = 1000000000
const outputDigits = 9
const primeLimit = 31623

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var composite = newSeq[bool](primeLimit + 1)
var primes = newSeq[int](0)
for candidate in 2 .. primeLimit:
  if not composite[candidate]:
    primes.add candidate
    var multiple = candidate * candidate
    while multiple <= primeLimit:
      composite[multiple] = true
      multiple += candidate

proc addExponent(table: var Table[int, int], primeValue: int) =
  if table.hasKey(primeValue):
    table[primeValue] = table[primeValue] + 1
  else:
    table[primeValue] = 1

proc factorize(value: int, table: var Table[int, int]) =
  var remaining = value
  var primeIndex = 0
  while primeIndex < primes.len and primes[primeIndex] * primes[primeIndex] <= remaining:
    let primeValue = primes[primeIndex]
    while remaining mod primeValue == 0:
      addExponent(table, primeValue)
      remaining = remaining div primeValue
    primeIndex += 1
  if remaining > 1:
    addExponent(table, remaining)

let factorCountFirst = nextInt(inputData, scanPos)
var exponentsFirst = initTable[int, int]()
for factorIndex in 0 .. factorCountFirst - 1:
  factorize(nextInt(inputData, scanPos), exponentsFirst)
let factorCountSecond = nextInt(inputData, scanPos)
var exponentsSecond = initTable[int, int]()
for factorIndex in 0 .. factorCountSecond - 1:
  factorize(nextInt(inputData, scanPos), exponentsSecond)

var remainder: int64 = 1
var exceedsLimit = false
for primeValue in exponentsFirst.keys:
  if not exponentsSecond.hasKey(primeValue):
    continue
  var exponent = exponentsFirst[primeValue]
  let otherExponent = exponentsSecond[primeValue]
  if otherExponent < exponent:
    exponent = otherExponent
  for powerIndex in 0 .. exponent - 1:
    let multiplier = int64(primeValue)
    if exceedsLimit:
      remainder = (remainder * multiplier) mod int64(digitLimit)
    else:
      let product = remainder * multiplier
      if product >= int64(digitLimit):
        exceedsLimit = true
      remainder = product mod int64(digitLimit)

if exceedsLimit:
  let digits = $remainder
  var padded = ""
  for padIndex in 0 .. outputDigits - digits.len - 1:
    padded.add '0'
  padded.add digits
  appendOutput padded
else:
  appendOutput $remainder
appendOutput "\n"
stdout.write outputBuffer
outputBuffer.setLen 0

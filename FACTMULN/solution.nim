const flushBlockBytes = 1 shl 17
const sieveLimit = 31623
const largestNumber = 1000000000

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

proc valuationAt(prime: int64, limit: int64): int64 =
  var power = prime
  while power <= limit:
    let quotient = limit div power
    result = result + power * quotient * (quotient - 1) div 2
    result = result + quotient * (limit - power * quotient + 1)
    if power > limit div prime:
      break
    power = power * prime
  return result

proc minimalIndex(prime: int, exponent: int): int =
  var low = int64(prime)
  var high = int64(largestNumber - 1)
  while low < high:
    let middle = low + (high - low) div 2
    if valuationAt(int64(prime), middle) >= int64(exponent):
      high = middle
    else:
      low = middle + 1
  return int(low)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var isComposite = newSeq[bool](sieveLimit + 1)
var primes = newSeq[int]()
for candidate in 2 .. sieveLimit:
  if not isComposite[candidate]:
    primes.add candidate
    if int64(candidate) * int64(candidate) <= sieveLimit:
      var multiple = candidate * candidate
      while multiple <= sieveLimit:
        isComposite[multiple] = true
        multiple += candidate

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let numberValue = nextInt(inputData, scanPos)
  var answer = 1
  var remaining = numberValue
  for prime in primes:
    if int64(prime) * int64(prime) > int64(remaining):
      break
    if remaining mod prime == 0:
      var exponent = 0
      while remaining mod prime == 0:
        remaining = remaining div prime
        exponent += 1
      let needed = minimalIndex(prime, exponent)
      if needed > answer:
        answer = needed
  if remaining > 1:
    let needed = minimalIndex(remaining, 1)
    if needed > answer:
      answer = needed
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

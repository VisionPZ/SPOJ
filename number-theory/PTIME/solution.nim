const flushBlockBytes = 1 shl 17
const maxPrimeLimit = 10000

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

var isComposite = newSeq[bool](maxPrimeLimit + 1)
var primes: seq[int] = @[]
for candidate in 2 .. maxPrimeLimit:
  if not isComposite[candidate]:
    primes.add candidate
    if candidate * candidate <= maxPrimeLimit:
      var multiple = candidate * candidate
      while multiple <= maxPrimeLimit:
        isComposite[multiple] = true
        multiple += candidate

while scanPos < inputData.len:
  let limitValue = nextInt(inputData, scanPos)
  if limitValue < 2:
    break
  var firstTerm = true
  for primeValue in primes:
    if primeValue > limitValue:
      break
    var power = primeValue
    var exponent = 0
    while power <= limitValue:
      exponent += limitValue div power
      if power > limitValue div primeValue:
        break
      power *= primeValue
    if not firstTerm:
      appendOutput(" * ")
    firstTerm = false
    appendOutput($primeValue)
    appendOutput("^")
    appendOutput($exponent)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const maxPrimeValue = 1000

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

var primeFlags = newSeq[bool](maxPrimeValue + 1)
for candidate in 2 .. maxPrimeValue:
  primeFlags[candidate] = true
var factor = 2
while factor * factor <= maxPrimeValue:
  if primeFlags[factor]:
    var multiple = factor * factor
    while multiple <= maxPrimeValue:
      primeFlags[multiple] = false
      multiple += factor
  factor += 1

var descendingPrimes = newSeq[int](0)
for candidate in countdown(maxPrimeValue, 2):
  if primeFlags[candidate]:
    descendingPrimes.add candidate

var rowCount = nextInt(inputData, scanPos)
var primeIndex = 0
var rowWidth = 1
while rowCount > 0 and primeIndex < descendingPrimes.len:
  var column = 0
  while column < rowWidth and primeIndex < descendingPrimes.len:
    if column > 0:
      appendOutput(" ")
    appendOutput($descendingPrimes[primeIndex])
    primeIndex += 1
    column += 1
  appendOutput("\n")
  rowWidth += 1
  rowCount -= 1
stdout.write outputBuffer
outputBuffer.setLen 0

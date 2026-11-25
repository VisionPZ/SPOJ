const flushBlockBytes = 1 shl 17

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

let testCaseCount = nextInt(inputData, scanPos)
for testCase in 0 .. testCaseCount - 1:
  let squareSide = nextInt(inputData, scanPos)
  if squareSide mod 2 == 1:
    appendOutput("0")
  else:
    var remainingFactor = squareSide
    var exponentOfTwo = 0
    while remainingFactor mod 2 == 0:
      exponentOfTwo += 1
      remainingFactor = remainingFactor div 2
    var divisorCount = 2 * exponentOfTwo
    var trialPrime = 3
    while trialPrime * trialPrime <= remainingFactor:
      var primeExponent = 0
      while remainingFactor mod trialPrime == 0:
        primeExponent += 1
        remainingFactor = remainingFactor div trialPrime
      if primeExponent > 0:
        divisorCount = divisorCount * (2 * primeExponent + 1)
      trialPrime += 2
    if remainingFactor > 1:
      divisorCount = divisorCount * 3
    appendOutput($divisorCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

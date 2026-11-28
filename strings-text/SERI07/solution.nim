const primeLimit = 351000
const termCount = 10000
const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, pos: var int): int =
  while pos < inputData.len and (inputData[pos] < '0' or inputData[pos] > '9'):
    pos += 1
  var value = 0
  while pos < inputData.len and inputData[pos] >= '0' and inputData[pos] <= '9':
    value = value * 10 + int(inputData[pos]) - 48
    pos += 1
  return value

proc buildTermTexts(): seq[string] =
  var composite = newSeq[bool](primeLimit + 1)
  var primes: seq[int] = @[]
  for value in 2 .. primeLimit:
    if not composite[value]:
      primes.add value
      if primes.len >= 3 * termCount:
        break
      var multiple = value * value
      while multiple <= primeLimit:
        composite[multiple] = true
        multiple += value
  result = @[]
  for index in 0 ..< termCount:
    let baseIndex = 3 * index
    let termValue = primes[baseIndex] * primes[baseIndex + 1] + primes[baseIndex + 2]
    result.add $termValue

var termTexts = buildTermTexts()

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var pos = 0
let caseCount = nextInt(inputData, pos)
var outputBuffer = ""
for _ in 0 ..< caseCount:
  let termIndex = nextInt(inputData, pos)
  for index in 0 ..< termIndex:
    if index > 0:
      outputBuffer.add ' '
    outputBuffer.add termTexts[index]
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer

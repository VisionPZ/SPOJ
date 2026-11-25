const flushBlockBytes = 1 shl 17
const sieveLimit = 10000000

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

var isPrime = newSeq[bool](sieveLimit + 1)
var primeCursor = 2
while primeCursor <= sieveLimit:
  isPrime[primeCursor] = true
  primeCursor += 1
isPrime[0] = false
isPrime[1] = false
var sieveCursor = 2
while int64(sieveCursor) * int64(sieveCursor) <= int64(sieveLimit):
  if isPrime[sieveCursor]:
    var multipleCursor = sieveCursor * sieveCursor
    while multipleCursor <= sieveLimit:
      isPrime[multipleCursor] = false
      multipleCursor += sieveCursor
  sieveCursor += 1
var primeList = newSeq[int](0)
var collectCursor = 2
while collectCursor <= sieveLimit:
  if isPrime[collectCursor]:
    primeList.add collectCursor
  collectCursor += 1

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let targetNumber = nextInt(inputData, scanPos)
  var remainingValue = int64(targetNumber)
  var factorBases = newSeq[int64](0)
  var factorPowers = newSeq[int](0)
  for primeValue in primeList:
    if int64(primeValue) * int64(primeValue) > remainingValue:
      break
    if remainingValue mod int64(primeValue) == 0:
      var powerCount = 0
      while remainingValue mod int64(primeValue) == 0:
        remainingValue = remainingValue div int64(primeValue)
        powerCount += 1
      factorBases.add int64(primeValue)
      factorPowers.add powerCount
  if remainingValue > 1:
    factorBases.add remainingValue
    factorPowers.add 1
  var divisorSum: int64 = 1
  for factorIndex in 0 .. factorBases.len - 1:
    var geometricSum: int64 = 1
    var currentPower: int64 = 1
    var exponentCursor = 0
    while exponentCursor < factorPowers[factorIndex]:
      currentPower = currentPower * factorBases[factorIndex]
      geometricSum = geometricSum + currentPower
      exponentCursor += 1
    divisorSum = divisorSum * geometricSum
  for factorIndex in 0 .. factorBases.len - 1:
    appendOutput($factorBases[factorIndex] & " " & $factorPowers[factorIndex] & "\n")
  appendOutput("Sum Of Divisiors: " & $divisorSum & "\n")
  if caseIndex < caseCount - 1:
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0

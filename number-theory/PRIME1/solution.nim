import sequtils

const rootLimit = 31623
const flushBlockBytes = 1 shl 17

proc basePrimes(): seq[int] =
  var composite = repeat(false, rootLimit + 1)
  var primes: seq[int]
  for value in 2 .. rootLimit:
    if not composite[value]:
      primes.add value
      var multiple = value * value
      while multiple <= rootLimit:
        composite[multiple] = true
        multiple = multiple + value
  return primes

proc primeList(windowLow, windowHigh: int, smallPrimes: seq[int]): seq[int] =
  var marked = repeat(false, windowHigh - windowLow + 1)
  for basePrime in smallPrimes:
    if basePrime * basePrime > windowHigh: break
    var markValue = max(basePrime * basePrime, (windowLow + basePrime - 1) div basePrime * basePrime)
    while markValue <= windowHigh:
      marked[markValue - windowLow] = true
      markValue = markValue + basePrime
  var primes: seq[int]
  for value in windowLow .. windowHigh:
    if value > 1 and not marked[value - windowLow]: primes.add value
  return primes

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  return value

var smallPrimes = basePrimes()
var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var i = 0
var caseCount = nextInt(inputData, i)
var outputBuffer: string
for _ in 1 .. caseCount:
  var windowLow = nextInt(inputData, i)
  var windowHigh = nextInt(inputData, i)
  for prime in primeList(windowLow, windowHigh, smallPrimes):
    outputBuffer.add $prime
    outputBuffer.add "\n"
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer

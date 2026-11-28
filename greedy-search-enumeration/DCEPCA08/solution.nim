const flushBlockBytes = 1 shl 17
const residueModulus = 53
const periodLength = 52

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

var periodValues = newSeq[int](periodLength)
var prefixSums = newSeq[int](periodLength + 1)
var powerValue = 1
for position in 1 .. periodLength:
  powerValue = (powerValue * (residueModulus - 2)) mod residueModulus
  periodValues[position - 1] = powerValue
  prefixSums[position] = prefixSums[position - 1] + powerValue
let periodSum = prefixSums[periodLength]

let caseCount = nextInt(inputData, scanPos)
var lengths = newSeq[int](caseCount)
var largestLength = 0
for caseIndex in 0 .. caseCount - 1:
  lengths[caseIndex] = nextInt(inputData, scanPos)
  if lengths[caseIndex] > largestLength:
    largestLength = lengths[caseIndex]
let largestSum = (largestLength div periodLength) * periodSum + prefixSums[largestLength mod periodLength]

var primeFlags = newSeq[bool](largestSum + 1)
for value in 0 .. largestSum:
  primeFlags[value] = true
primeFlags[0] = false
primeFlags[1] = false
var divisor = 2
while divisor * divisor <= largestSum:
  if primeFlags[divisor]:
    var multiple = divisor * divisor
    while multiple <= largestSum:
      primeFlags[multiple] = false
      multiple += divisor
  divisor += 1
var primeCounts = newSeq[int](largestSum + 1)
for value in 1 .. largestSum:
  primeCounts[value] = primeCounts[value - 1]
  if primeFlags[value]:
    primeCounts[value] += 1

for caseIndex in 0 .. caseCount - 1:
  let length = lengths[caseIndex]
  let cycles = length div periodLength
  let remainder = length mod periodLength
  let totalSum = cycles * periodSum + prefixSums[remainder]
  if length >= periodLength:
    appendOutput($primeCounts[totalSum])
  else:
    var reachable = newSeq[bool](totalSum + 1)
    reachable[0] = true
    for position in 0 .. length - 1:
      let value = periodValues[position]
      var score = totalSum
      while score >= value:
        if reachable[score - value]:
          reachable[score] = true
        score -= 1
    var primeSubsetCount = 0
    for score in 2 .. totalSum:
      if primeFlags[score] and reachable[score]:
        primeSubsetCount += 1
    appendOutput($primeSubsetCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

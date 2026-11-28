const flushBlockBytes = 1 shl 17
const limitValue = 1000000

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

var smallestPrime = newSeq[int](limitValue + 1)
var candidate = 2
while int64(candidate) * int64(candidate) <= int64(limitValue):
  if smallestPrime[candidate] == 0:
    smallestPrime[candidate] = candidate
    var multiple = int64(candidate) * int64(candidate)
    while multiple <= int64(limitValue):
      if smallestPrime[int(multiple)] == 0:
        smallestPrime[int(multiple)] = candidate
      multiple = multiple + int64(candidate)
  candidate += 1
for numberValue in 2 .. limitValue:
  if smallestPrime[numberValue] == 0:
    smallestPrime[numberValue] = numberValue

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  var numberValue = nextInt(inputData, scanPos)
  var firstFactor = true
  while numberValue > 1:
    let factorValue = smallestPrime[numberValue]
    if not firstFactor:
      appendOutput(" ")
    appendOutput($factorValue)
    firstFactor = false
    numberValue = numberValue div factorValue
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const modulusMask = 4294967295'u64
const wideModulusMask = 8589934591'u64
const highestBit = 63

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

var powersOfThree = newSeq[uint64](highestBit + 1)
var lowerContributions = newSeq[uint64](highestBit + 1)
var runningPower = 1'u64
var widePower = 1'u64
for bitIndex in 0 .. highestBit:
  powersOfThree[bitIndex] = runningPower
  if bitIndex > 0:
    let oddPart = ((widePower - 1'u64) and wideModulusMask) div 2'u64
    lowerContributions[bitIndex] = (oddPart * (1'u64 shl (bitIndex - 1))) and modulusMask
  runningPower = (runningPower * 3'u64) and modulusMask
  widePower = (widePower * 3'u64) and wideModulusMask

proc prefixSum(limitValue: uint64): uint64 =
  var accumulated = 0'u64
  var builtValue = 0'u64
  for bitIndex in countdown(highestBit, 0):
    let bitSelector = 1'u64 shl bitIndex
    if (limitValue and bitSelector) != 0'u64:
      accumulated = (accumulated + builtValue * bitSelector + lowerContributions[bitIndex]) and modulusMask
      builtValue = (builtValue + powersOfThree[bitIndex]) and modulusMask
  return accumulated

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let leftBound = uint64(nextInt(inputData, scanPos))
  let rightBound = uint64(nextInt(inputData, scanPos))
  let beforeLeft = prefixSum(leftBound)
  let beforeRight = prefixSum(rightBound + 1'u64)
  let rangeSum = (beforeRight - beforeLeft) and modulusMask
  appendOutput($rangeSum)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const modulusValue = 1000000000

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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let sequenceLength = nextInt(inputData, scanPos)
  let bitCount = nextInt(inputData, scanPos)
  var forbiddenDivisors = newSeq[int](sequenceLength)
  for position in 0 .. sequenceLength - 1:
    forbiddenDivisors[position] = nextInt(inputData, scanPos)
  let stateCount = 1 shl bitCount
  let fullMask = stateCount - 1
  var complementOf = newSeq[int](stateCount)
  for value in 0 .. stateCount - 1:
    complementOf[value] = fullMask xor value
  var allowedByDivisor = newSeq[seq[bool]](2 * bitCount + 1)
  for divisor in 1 .. 2 * bitCount:
    var allowedHere = newSeq[bool](stateCount)
    for value in 0 .. stateCount - 1:
      allowedHere[value] = value mod divisor != 0
    allowedByDivisor[divisor] = allowedHere
  var waysEnding = newSeq[int64](stateCount)
  var nextWays = newSeq[int64](stateCount)
  var subsetTotals = newSeq[int64](stateCount)
  let firstAllowed = allowedByDivisor[forbiddenDivisors[0]]
  for value in 0 .. stateCount - 1:
    if firstAllowed[value]:
      waysEnding[value] = 1
  if sequenceLength > 1:
    for position in 1 .. sequenceLength - 1:
      for value in 0 .. stateCount - 1:
        subsetTotals[value] = waysEnding[value]
      for bitIndex in 0 .. bitCount - 1:
        let bitValue = 1 shl bitIndex
        for value in 0 .. stateCount - 1:
          if (value and bitValue) != 0:
            subsetTotals[value] = subsetTotals[value] + subsetTotals[value - bitValue]
      let allowedHere = allowedByDivisor[forbiddenDivisors[position]]
      for value in 0 .. stateCount - 1:
        if allowedHere[value]:
          nextWays[value] = subsetTotals[complementOf[value]] mod int64(modulusValue)
        else:
          nextWays[value] = 0
      swap waysEnding, nextWays
  var totalWays: int64 = 0
  for value in 0 .. stateCount - 1:
    totalWays = (totalWays + waysEnding[value]) mod int64(modulusValue)
  appendOutput($totalWays)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

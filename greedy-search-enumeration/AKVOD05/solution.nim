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

let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let targetPosition = nextInt(inputData, scanPos)
  let windowSize = nextInt(inputData, scanPos)
  let periodStart = 2 * windowSize + 1
  let simulationEnd = periodStart + windowSize + 1
  var sequence = newSeq[int](simulationEnd + 1)
  var frequency = newSeq[int](windowSize + 2)
  for position in 0 .. windowSize - 1:
    let knownValue = nextInt(inputData, scanPos)
    sequence[position] = knownValue
    if knownValue >= 0 and knownValue <= windowSize:
      frequency[knownValue] += 1
  var currentMex = 0
  while frequency[currentMex] > 0:
    currentMex += 1
  for position in windowSize .. simulationEnd:
    let generatedValue = currentMex
    sequence[position] = generatedValue
    let expiredValue = sequence[position - windowSize]
    if expiredValue >= 0 and expiredValue <= windowSize:
      frequency[expiredValue] -= 1
      if frequency[expiredValue] == 0 and expiredValue < currentMex:
        currentMex = expiredValue
    frequency[generatedValue] += 1
    while frequency[currentMex] > 0:
      currentMex += 1
  let targetIndex = targetPosition - 1
  if targetIndex < periodStart:
    appendOutput($sequence[targetIndex])
  else:
    let periodLength = windowSize + 1
    let withinPeriod = (targetIndex - periodStart) mod periodLength
    appendOutput($sequence[periodStart + withinPeriod])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

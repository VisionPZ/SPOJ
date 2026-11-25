const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextNatural(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = int64(0)
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value

proc hasMoreNatural(data: string, pos: int): bool =
  var probe = pos
  while probe < data.len and (data[probe] < '0' or data[probe] > '9'):
    probe += 1
  return probe < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasMoreNatural(inputData, scanPos):
  let original = nextNatural(inputData, scanPos)
  var remaining = original
  var divisor = int64(2)
  var factorCount = 0
  while divisor <= remaining div divisor:
    while remaining mod divisor == 0:
      if factorCount > 0:
        appendOutput(" x ")
      appendOutput($(divisor))
      factorCount += 1
      remaining = remaining div divisor
    if divisor == 2:
      divisor = 3
    else:
      divisor += 2
  if remaining > 1:
    if factorCount > 0:
      appendOutput(" x ")
    appendOutput($(remaining))
    factorCount += 1
  if factorCount == 0:
    appendOutput($(original))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

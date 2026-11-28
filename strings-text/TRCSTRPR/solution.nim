const maxPrimeValue = 30000
const flushBlockBytes = 1 shl 17

var isPrimeTable = newSeq[bool](maxPrimeValue + 1)
var tablePos = 2
while tablePos <= maxPrimeValue:
  isPrimeTable[tablePos] = true
  tablePos += 1
var baseValue = 2
while baseValue * baseValue <= maxPrimeValue:
  if isPrimeTable[baseValue]:
    var multiple = baseValue * baseValue
    while multiple <= maxPrimeValue:
      isPrimeTable[multiple] = false
      multiple += baseValue
  baseValue += 1

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let startPos = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[startPos ..< pos]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let listSize = nextInt(inputData, scanPos)
for _ in 0..<listSize:
  let personName = nextToken(inputData, scanPos)
  let addedNumber = nextInt(inputData, scanPos)
  var hasPrime = false
  for k in 0..<personName.len:
    let shiftedValue = int(personName[k]) + addedNumber
    if shiftedValue <= maxPrimeValue and isPrimeTable[shiftedValue]:
      hasPrime = true
      break
  if hasPrime:
    appendOutput("YES\n")
  else:
    appendOutput("NO\n")

stdout.write outputBuffer
outputBuffer.setLen 0

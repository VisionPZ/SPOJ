const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const baseLetter = 97
const alphabetSize = 26
const knownCost = 50
const unknownCost = 150

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
    value = value * 10 + int(data[pos]) - firstDigitValue
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

let caseCount = int(nextInt(inputData, scanPos))
for j in 0..<caseCount:
  let knownLetters = nextToken(inputData, scanPos)
  let textToType = nextToken(inputData, scanPos)
  var known = newSeq[bool](alphabetSize)
  var seen = newSeq[bool](alphabetSize)
  for c in knownLetters:
    known[int(c) - baseLetter] = true
  var totalCost: int64 = knownCost * int64(textToType.len)
  for c in textToType:
    let idx = int(c) - baseLetter
    if not known[idx] and not seen[idx]:
      seen[idx] = true
      totalCost += int64(unknownCost - knownCost)
  appendOutput($(totalCost))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

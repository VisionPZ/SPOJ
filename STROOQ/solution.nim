const flushBlockBytes = 1 shl 17
const residuesPerBlock = 4
const blockSpan = 1000
const firstResidue = 192
const residueGap = 250

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
  let rank = nextInt(inputData, scanPos)
  let blockIndex = (rank - 1) div residuesPerBlock
  let residueIndex = (rank - 1) mod residuesPerBlock
  let answer = blockIndex * blockSpan + firstResidue + residueIndex * residueGap
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

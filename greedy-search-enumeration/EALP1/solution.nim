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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let pileCount = nextInt(inputData, scanPos)
  var pileSizes = newSeq[int](pileCount)
  var nimXor = 0
  for pileIndex in 0 .. pileCount - 1:
    pileSizes[pileIndex] = nextInt(inputData, scanPos)
    nimXor = nimXor xor pileSizes[pileIndex]
  var winningMoves = 0
  if nimXor != 0:
    for pileIndex in 0 .. pileCount - 1:
      if (pileSizes[pileIndex] xor nimXor) < pileSizes[pileIndex]:
        winningMoves += 1
  appendOutput("Case " & $caseIndex & ": " & $winningMoves)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

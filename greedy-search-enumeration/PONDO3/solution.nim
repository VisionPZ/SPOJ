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

let pondoCount = nextInt(inputData, scanPos)
let bombooCount = int64(nextInt(inputData, scanPos))
var survivalDays = newSeq[int64](pondoCount)
var longestLife: int64 = 0
for pondoIndex in 0 .. pondoCount - 1:
  survivalDays[pondoIndex] = int64(nextInt(inputData, scanPos))
  if survivalDays[pondoIndex] > longestLife:
    longestLife = survivalDays[pondoIndex]
var lowDays: int64 = 0
var highDays = bombooCount * longestLife
while lowDays < highDays:
  let midDays = (lowDays + highDays + 1) div 2
  var neededBomboo: int64 = 0
  for pondoIndex in 0 .. pondoCount - 1:
    neededBomboo += (midDays + survivalDays[pondoIndex] - 1) div survivalDays[pondoIndex]
    if neededBomboo > bombooCount:
      break
  if neededBomboo <= bombooCount:
    lowDays = midDays
  else:
    highDays = midDays - 1
appendOutput($lowDays)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

{.push checks: off.}
{.passC: "-O3".}

import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc canPlace(stalls: seq[int], cowCount, gap: int): bool =
  var placedCount = 1
  var lastIndex = 0
  for i in 1..<stalls.len:
    if stalls[i] - stalls[lastIndex] >= gap:
      placedCount += 1
      lastIndex = i
      if placedCount >= cowCount: return true
  return cowCount <= 1

var stalls: seq[int] = @[]

let caseCount = nextInt(inputData, scanPos)
for j in 0..<caseCount:
  let stallCount = nextInt(inputData, scanPos)
  let cowCount = nextInt(inputData, scanPos)
  stalls.setLen(stallCount)
  for i in 0..<stallCount:
    stalls[i] = nextInt(inputData, scanPos)
  stalls.sort(system.cmp[int])
  var lowGap = 0
  var highGap = stalls[stallCount - 1] - stalls[0] + 1
  while lowGap < highGap:
    let midGap = (lowGap + highGap + 1) div 2
    if canPlace(stalls, cowCount, midGap):
      lowGap = midGap
    else:
      highGap = midGap - 1
  appendOutput($(lowGap))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const maxBars = 100005

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

var stackHeight = newSeq[int64](maxBars)
var stackStart = newSeq[int](maxBars)

while scanPos < inputData.len:
  let barCount = nextInt(inputData, scanPos)
  if barCount == 0:
    break
  var stackTop = 0
  var bestArea: int64 = 0
  for barIdx in 0 .. barCount:
    let currentHeight = if barIdx < barCount: int64(nextInt(inputData, scanPos)) else: 0'i64
    var spanStart = barIdx
    while stackTop > 0 and stackHeight[stackTop - 1] >= currentHeight:
      stackTop -= 1
      let width = int64(barIdx - stackStart[stackTop])
      let area = stackHeight[stackTop] * width
      if area > bestArea:
        bestArea = area
      spanStart = stackStart[stackTop]
    if currentHeight > 0:
      stackHeight[stackTop] = currentHeight
      stackStart[stackTop] = spanStart
      stackTop += 1
  appendOutput($bestArea)
  appendOutput("\n")

if outputBuffer.len > 0:
  stdout.write outputBuffer
  outputBuffer.setLen 0

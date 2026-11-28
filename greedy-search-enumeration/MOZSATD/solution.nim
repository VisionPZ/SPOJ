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

let salamiCount = nextInt(inputData, scanPos)
var totalTaka: int64 = 0
var smallestOddAmount: int64 = 0
var hasOddAmount = false
for salamiIndex in 0 .. salamiCount - 1:
  let salamiAmount = int64(nextInt(inputData, scanPos))
  totalTaka += salamiAmount
  if salamiAmount mod 2 == 1:
    if not hasOddAmount or salamiAmount < smallestOddAmount:
      smallestOddAmount = salamiAmount
      hasOddAmount = true
var sharedTaka: int64 = 0
if totalTaka mod 2 == 0:
  sharedTaka = totalTaka div 2
else:
  sharedTaka = (totalTaka - smallestOddAmount) div 2
appendOutput($sharedTaka)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

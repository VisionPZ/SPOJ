const flushBlockBytes = 1 shl 17

var inputData = ""
var byteBuffer: array[65536, char]
while true:
  let bytesRead = stdin.readBuffer(addr byteBuffer[0], byteBuffer.len)
  if bytesRead == 0:
    break
  for byteIndex in 0 .. bytesRead - 1:
    inputData.add byteBuffer[byteIndex]

var textStart = 0
while textStart < inputData.len and inputData[textStart] != '\n':
  textStart += 1
if textStart < inputData.len:
  textStart += 1

var frequencies: array[256, int]
for byteIndex in textStart .. inputData.len - 1:
  frequencies[int(inputData[byteIndex])] += 1

var sortedBytes = newSeq[int](256)
var sortedLength = 0
for byteValue in 0 .. 255:
  if frequencies[byteValue] > 0:
    sortedBytes[sortedLength] = byteValue
    sortedLength += 1

for sortIndex in 1 .. sortedLength - 1:
  let currentByte = sortedBytes[sortIndex]
  var compareIndex = sortIndex - 1
  while compareIndex >= 0:
    let priorByte = sortedBytes[compareIndex]
    let priorHigher = frequencies[priorByte] > frequencies[currentByte] or
        (frequencies[priorByte] == frequencies[currentByte] and priorByte > currentByte)
    if not priorHigher:
      break
    sortedBytes[compareIndex + 1] = priorByte
    compareIndex -= 1
  sortedBytes[compareIndex + 1] = currentByte

var substitution: array[256, int]
for position in 0 .. sortedLength - 1:
  substitution[sortedBytes[position]] = sortedBytes[sortedLength - 1 - position]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for byteIndex in textStart .. inputData.len - 1:
  appendOutput($chr(substitution[int(inputData[byteIndex])]))
stdout.write outputBuffer
outputBuffer.setLen 0

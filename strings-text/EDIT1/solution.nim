const readChunkBytes = 65536
const flushBlockBytes = 1 shl 17
const newlineKey = '\n'
const duplicateKey = 'd'

proc doubleLine(line: var string) =
  let originalLength = line.len
  let doubledLength = originalLength * 2
  line.setLen(doubledLength)
  for i in 0 ..< originalLength:
    line[originalLength + i] = line[i]

var inputData = newString(readChunkBytes)
var bytesRead = 0
while true:
  if bytesRead + readChunkBytes > inputData.len:
    inputData.setLen(inputData.len + readChunkBytes)
  let received = stdin.readBuffer(addr inputData[bytesRead], readChunkBytes)
  if received == 0:
    break
  bytesRead += received
inputData.setLen(bytesRead)

var currentLine = ""
var outputBuffer = ""
var i = 0

while i < inputData.len:
  let keyByte = inputData[i]
  if keyByte == newlineKey:
    i += 1
    if currentLine.len == 0:
      break
    outputBuffer.add currentLine
    outputBuffer.add newlineKey
    currentLine.setLen(0)
    if outputBuffer.len >= flushBlockBytes:
      stdout.write outputBuffer
      outputBuffer.setLen(0)
  elif keyByte == duplicateKey:
    i += 1
    doubleLine(currentLine)
  else:
    currentLine.add keyByte
    i += 1

if currentLine.len > 0:
  outputBuffer.add currentLine
  outputBuffer.add newlineKey
stdout.write outputBuffer

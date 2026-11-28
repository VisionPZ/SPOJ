const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt(data: string, position: var int, found: var bool): int =
  while position < data.len and data[position] != '-' and (data[position] < '0' or data[position] > '9'):
    position += 1
  if position >= data.len:
    found = false
    return 0
  var signValue = 1
  if data[position] == '-':
    signValue = -1
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  found = true
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc spacesOf(count: int): string =
  var builtLine = newString(count)
  var fillIndex = 0
  while fillIndex < count:
    builtLine[fillIndex] = ' '
    fillIndex += 1
  return builtLine

proc starLine(starCount: int): string =
  var builtLine = newString(2 * starCount - 1)
  var writeIndex = 0
  while writeIndex < builtLine.len:
    builtLine[writeIndex] = '*'
    writeIndex += 1
    if writeIndex < builtLine.len:
      builtLine[writeIndex] = ' '
      writeIndex += 1
  return builtLine

var heightFound = false
while true:
  let pyramidHeight = nextSignedInt(inputData, scanPos, heightFound)
  if not heightFound:
    break
  if pyramidHeight <= 0:
    appendOutput("\n")
  else:
    for rowIndex in 0 ..< pyramidHeight:
      let starCount = 2 * (pyramidHeight - rowIndex) - 1
      appendOutput(spacesOf(2 * rowIndex) & starLine(starCount) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0

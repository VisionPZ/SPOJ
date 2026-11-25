const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

proc encryptText(key: string, plain: string): string =
  let columnCount = key.len
  var columnTexts = newSeq[string](columnCount)
  var letterPos = 0
  var rowStart = 0
  while letterPos < plain.len:
    for columnIndex in 0 .. columnCount - 1:
      var takeCount = 1
      if (columnIndex + rowStart) mod 2 == 0:
        takeCount = 2
      let remaining = plain.len - letterPos
      if remaining < takeCount:
        takeCount = remaining
      if takeCount == 0:
        break
      columnTexts[columnIndex].add plain.substr(letterPos, letterPos + takeCount - 1)
      letterPos += takeCount
    if columnCount mod 2 == 1:
      rowStart = 1 - rowStart
  var cipherText = ""
  for digitValue in 1 .. columnCount:
    for columnIndex in 0 .. columnCount - 1:
      if int(key[columnIndex]) - 48 == digitValue:
        cipherText.add columnTexts[columnIndex]
        break
  return cipherText

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let key = nextToken(inputData, scanPos)
  if key.len == 0:
    break
  let plain = nextToken(inputData, scanPos)
  if plain.len == 0:
    break
  appendOutput(encryptText(key, plain))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

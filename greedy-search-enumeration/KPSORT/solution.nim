const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let sequenceLength = nextInt(inputData, scanPos)
  if sequenceLength == 0:
    break
  var sequenceValues = newSeq[int](sequenceLength)
  for valueIndex in 0 .. sequenceLength - 1:
    sequenceValues[valueIndex] = nextInt(inputData, scanPos)
  if sequenceLength == 1:
    appendOutput("1")
  elif sequenceLength == 2:
    if sequenceValues[0] <= sequenceValues[1]:
      appendOutput("1")
    else:
      appendOutput("0")
  elif sequenceLength mod 2 == 1 or sequenceLength mod 4 == 0:
    appendOutput("1")
  else:
    var hasEqualValues = false
    for leftIndex in 0 .. sequenceLength - 1:
      for rightIndex in leftIndex + 1 .. sequenceLength - 1:
        if sequenceValues[leftIndex] == sequenceValues[rightIndex]:
          hasEqualValues = true
    if hasEqualValues:
      appendOutput("1")
    else:
      var inversionParity = 0
      for leftIndex in 0 .. sequenceLength - 1:
        for rightIndex in leftIndex + 1 .. sequenceLength - 1:
          if sequenceValues[leftIndex] > sequenceValues[rightIndex]:
            inversionParity = 1 - inversionParity
      if inversionParity == 0:
        appendOutput("1")
      else:
        appendOutput("0")

outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

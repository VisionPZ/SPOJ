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

let dataSetCount = nextInt(inputData, scanPos)
for dataSetIndex in 0 .. dataSetCount - 1:
  let peopleCount = nextInt(inputData, scanPos)
  var knowsMatrix = newSeq[int](peopleCount * peopleCount)
  for rowIndex in 0 .. peopleCount - 1:
    for columnIndex in 0 .. peopleCount - 1:
      knowsMatrix[rowIndex * peopleCount + columnIndex] = nextInt(inputData, scanPos)
  var candidate = 0
  for personIndex in 1 .. peopleCount - 1:
    if knowsMatrix[candidate * peopleCount + personIndex] == 1:
      candidate = personIndex
  var isVip = true
  for personIndex in 0 .. peopleCount - 1:
    if personIndex != candidate:
      if knowsMatrix[personIndex * peopleCount + candidate] != 1:
        isVip = false
      if knowsMatrix[candidate * peopleCount + personIndex] != 0:
        isVip = false
  if isVip:
    appendOutput($(candidate + 1))
  else:
    for personIndex in 0 .. peopleCount - 1:
      var knowsOnlySelf = true
      var knownByAll = true
      for otherIndex in 0 .. peopleCount - 1:
        if otherIndex != personIndex:
          if knowsMatrix[personIndex * peopleCount + otherIndex] != 0:
            knowsOnlySelf = false
          if knowsMatrix[otherIndex * peopleCount + personIndex] != 1:
            knownByAll = false
      if knowsOnlySelf and knownByAll:
        appendOutput($(personIndex + 1))
        break
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

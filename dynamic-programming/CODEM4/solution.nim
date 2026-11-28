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

let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let elementCount = nextInt(inputData, scanPos)
  var pickedValues = newSeq[int64](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    pickedValues[elementIndex] = int64(nextInt(inputData, scanPos))
  var smartScores = newSeq[int64](elementCount * elementCount)
  var dumbScores = newSeq[int64](elementCount * elementCount)
  for windowLength in 1 .. elementCount:
    for leftIndex in 0 .. elementCount - windowLength:
      let rightIndex = leftIndex + windowLength - 1
      let cellIndex = leftIndex * elementCount + rightIndex
      if windowLength == 1:
        smartScores[cellIndex] = 0
        dumbScores[cellIndex] = 0
      elif windowLength mod 2 == 0:
        let takeLeft = pickedValues[leftIndex] + smartScores[(leftIndex + 1) * elementCount + rightIndex]
        let takeRight = pickedValues[rightIndex] + smartScores[leftIndex * elementCount + rightIndex - 1]
        smartScores[cellIndex] = if takeLeft > takeRight: takeLeft else: takeRight
        let dumbLeft = pickedValues[leftIndex] + dumbScores[(leftIndex + 1) * elementCount + rightIndex]
        let dumbRight = pickedValues[rightIndex] + dumbScores[leftIndex * elementCount + rightIndex - 1]
        dumbScores[cellIndex] = if dumbLeft > dumbRight: dumbLeft else: dumbRight
      else:
        let smartLeft = smartScores[(leftIndex + 1) * elementCount + rightIndex]
        let smartRight = smartScores[leftIndex * elementCount + rightIndex - 1]
        smartScores[cellIndex] = if smartLeft < smartRight: smartLeft else: smartRight
        let dumbLeft = dumbScores[(leftIndex + 1) * elementCount + rightIndex]
        let dumbRight = dumbScores[leftIndex * elementCount + rightIndex - 1]
        dumbScores[cellIndex] = if dumbLeft > dumbRight: dumbLeft else: dumbRight
  appendOutput($dumbScores[elementCount - 1] & " " & $smartScores[elementCount - 1])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

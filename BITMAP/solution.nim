const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infDistance = 1000000000

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

proc nextBit(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '0' and data[pos] != '1':
    pos += 1
  let value = int(data[pos]) - firstDigitValue
  pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
var distance: seq[int] = @[]

for caseIndex in 0..<caseCount:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let cellCount = rowCount * columnCount
  distance.setLen cellCount
  for cellIndex in 0..<cellCount:
    if nextBit(inputData, scanPos) == 1:
      distance[cellIndex] = 0
    else:
      distance[cellIndex] = infDistance

  for i in 0..<rowCount:
    for j in 0..<columnCount:
      let cellIndex = i * columnCount + j
      if i > 0:
        let upIndex = cellIndex - columnCount
        let candidate = distance[upIndex] + 1
        if candidate < distance[cellIndex]:
          distance[cellIndex] = candidate
      if j > 0:
        let leftIndex = cellIndex - 1
        let candidate = distance[leftIndex] + 1
        if candidate < distance[cellIndex]:
          distance[cellIndex] = candidate

  for k in 0..<rowCount:
    let i = rowCount - 1 - k
    for l in 0..<columnCount:
      let j = columnCount - 1 - l
      let cellIndex = i * columnCount + j
      if i < rowCount - 1:
        let downIndex = cellIndex + columnCount
        let candidate = distance[downIndex] + 1
        if candidate < distance[cellIndex]:
          distance[cellIndex] = candidate
      if j < columnCount - 1:
        let rightIndex = cellIndex + 1
        let candidate = distance[rightIndex] + 1
        if candidate < distance[cellIndex]:
          distance[cellIndex] = candidate

  for i in 0..<rowCount:
    for j in 0..<columnCount:
      if j > 0:
        appendOutput " "
      appendOutput $(distance[i * columnCount + j])
    appendOutput "\n"

stdout.write outputBuffer
outputBuffer.setLen 0

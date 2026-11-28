const flushBlockBytes = 1 shl 17
const maxArraySize = 200000

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

var values = newSeq[int](maxArraySize)
var scratch = newSeq[int](maxArraySize)

proc countInversions(length: int): int64 =
  var totalInversions: int64 = 0
  var runWidth = 1
  while runWidth < length:
    var leftStart = 0
    while leftStart < length:
      let mid = leftStart + runWidth
      if mid >= length:
        for idx in leftStart .. length - 1:
          scratch[idx] = values[idx]
        break
      var rightEnd = mid + runWidth
      if rightEnd > length:
        rightEnd = length
      var leftIdx = leftStart
      var rightIdx = mid
      var writeIdx = leftStart
      while leftIdx < mid and rightIdx < rightEnd:
        if values[leftIdx] <= values[rightIdx]:
          scratch[writeIdx] = values[leftIdx]
          leftIdx += 1
        else:
          scratch[writeIdx] = values[rightIdx]
          totalInversions += int64(mid - leftIdx)
          rightIdx += 1
        writeIdx += 1
      while leftIdx < mid:
        scratch[writeIdx] = values[leftIdx]
        leftIdx += 1
        writeIdx += 1
      while rightIdx < rightEnd:
        scratch[writeIdx] = values[rightIdx]
        rightIdx += 1
        writeIdx += 1
      leftStart = rightEnd
    for idx in 0 .. length - 1:
      values[idx] = scratch[idx]
    runWidth = runWidth shl 1
  return totalInversions

let caseCount = nextInt(inputData, scanPos)
for caseIdx in 0 .. caseCount - 1:
  let elementCount = nextInt(inputData, scanPos)
  for idx in 0 .. elementCount - 1:
    values[idx] = nextInt(inputData, scanPos)
  let answer = countInversions(elementCount)
  appendOutput($answer)
  appendOutput("\n")

if outputBuffer.len > 0:
  stdout.write outputBuffer
  outputBuffer.setLen 0

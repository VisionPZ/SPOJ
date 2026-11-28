const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInteger(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var magnitude = int64(0)
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    magnitude = magnitude * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  if negative:
    return -magnitude
  return magnitude

proc hasMoreInteger(data: string, pos: int): bool =
  var probe = pos
  while probe < data.len and (data[probe] < '0' or data[probe] > '9') and data[probe] != '-':
    probe += 1
  return probe < data.len

proc sortValues(values: var seq[int64], leftIndex: int, rightIndex: int) =
  if leftIndex >= rightIndex: return
  var low = leftIndex
  var high = rightIndex
  let pivot = values[(leftIndex + rightIndex) div 2]
  while low <= high:
    while values[low] < pivot: low += 1
    while values[high] > pivot: high -= 1
    if low <= high:
      swap values[low], values[high]
      low += 1
      high -= 1
  if leftIndex < high: sortValues(values, leftIndex, high)
  if low < rightIndex: sortValues(values, low, rightIndex)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasMoreInteger(inputData, scanPos):
  let declaredCount = nextInteger(inputData, scanPos)
  if declaredCount <= 0:
    outputBuffer.add '\n'
    continue
  var values = newSeq[int64](int(declaredCount))
  var stored = 0
  while stored < int(declaredCount) and hasMoreInteger(inputData, scanPos):
    values[stored] = nextInteger(inputData, scanPos)
    stored += 1
  values.setLen(stored)
  if stored > 0:
    sortValues(values, 0, stored - 1)
    var frequencySlots = newSeq[int](stored + 1)
    var runStart = 0
    for index in 1..stored:
      if index == stored or values[index] != values[runStart]:
        let runLength = index - runStart
        frequencySlots[runLength] += 1
        runStart = index
    var printed = 0
    var frequency = stored
    while frequency >= 1:
      for occurrence in 0..<frequencySlots[frequency]:
        if printed > 0: outputBuffer.add ' '
        appendOutput($(frequency))
        printed += 1
      frequency -= 1
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

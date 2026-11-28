const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc runIndexAt(starts: seq[int], length: int, position: int): int =
  var low = 0
  var high = length - 1
  while low <= high:
    let middle = (low + high) div 2
    if starts[middle] <= position:
      low = middle + 1
    else:
      high = middle - 1
  return high

while true:
  let numberCount = nextInt(inputData, scanPos)
  if numberCount == 0:
    break
  let queryCount = nextInt(inputData, scanPos)
  var values = newSeq[int](numberCount)
  for valueIndex in 0 .. numberCount - 1:
    values[valueIndex] = nextInt(inputData, scanPos)
  var runStarts = newSeq[int](numberCount)
  var runLengths = newSeq[int](numberCount)
  var runCount = 0
  var valueIndex = 0
  while valueIndex < numberCount:
    runStarts[runCount] = valueIndex
    var runEnd = valueIndex + 1
    while runEnd < numberCount and values[runEnd] == values[valueIndex]:
      runEnd += 1
    runLengths[runCount] = runEnd - valueIndex
    runCount += 1
    valueIndex = runEnd
  var logarithms = newSeq[int](runCount + 1)
  for span in 2 .. runCount:
    logarithms[span] = logarithms[span div 2] + 1
  let levelCount = logarithms[runCount] + 1
  var table = newSeq[seq[int]](levelCount)
  table[0] = runLengths
  for level in 1 .. levelCount - 1:
    let halfSpan = 1 shl (level - 1)
    let entryCount = runCount - (1 shl level) + 1
    var row = newSeq[int](entryCount)
    for entryIndex in 0 .. entryCount - 1:
      let leftValue = table[level - 1][entryIndex]
      let rightValue = table[level - 1][entryIndex + halfSpan]
      if leftValue > rightValue:
        row[entryIndex] = leftValue
      else:
        row[entryIndex] = rightValue
    table[level] = row
  for queryIndex in 0 .. queryCount - 1:
    let leftPosition = nextInt(inputData, scanPos) - 1
    let rightPosition = nextInt(inputData, scanPos) - 1
    let leftRun = runIndexAt(runStarts, runCount, leftPosition)
    let rightRun = runIndexAt(runStarts, runCount, rightPosition)
    var bestCount: int
    if leftRun == rightRun:
      bestCount = rightPosition - leftPosition + 1
    else:
      let leftTail = runStarts[leftRun] + runLengths[leftRun] - leftPosition
      let rightHead = rightPosition - runStarts[rightRun] + 1
      bestCount = leftTail
      if rightHead > bestCount:
        bestCount = rightHead
      let innerLeft = leftRun + 1
      let innerRight = rightRun - 1
      if innerLeft <= innerRight:
        let span = innerRight - innerLeft + 1
        let level = logarithms[span]
        let offset = innerRight - (1 shl level) + 1
        var innerBest = table[level][innerLeft]
        let secondValue = table[level][offset]
        if secondValue > innerBest:
          innerBest = secondValue
        if innerBest > bestCount:
          bestCount = innerBest
    appendOutput($bestCount)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

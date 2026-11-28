import algorithm

const flushBlockBytes = 1 shl 17

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

proc compareValues(first, second: int64): int =
  if first < second: return -1
  if first > second: return 1
  return 0

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = int(nextInt(inputData, scanPos))
for caseIndex in 1..caseCount:
  let itemCount = int(nextInt(inputData, scanPos))
  let targetSum = nextInt(inputData, scanPos)
  var values: seq[int64] = @[]
  values.setLen(itemCount)
  for idx in 0..<itemCount:
    values[idx] = nextInt(inputData, scanPos)
  values.sort(compareValues)

  var pairCount: int64 = 0
  var leftPos = 0
  var rightPos = itemCount - 1
  while leftPos < rightPos:
    let pairSum = values[leftPos] + values[rightPos]
    if pairSum == targetSum:
      let leftValue = values[leftPos]
      var leftRun = 0
      while leftPos <= rightPos and values[leftPos] == leftValue:
        leftPos += 1
        leftRun += 1
      let rightValue = values[rightPos]
      var rightRun = 0
      while rightPos >= leftPos and values[rightPos] == rightValue:
        rightPos -= 1
        rightRun += 1
      if leftValue == rightValue:
        pairCount += int64(leftRun) * int64(leftRun - 1) div 2
      else:
        pairCount += int64(leftRun) * int64(rightRun)
    elif pairSum < targetSum:
      leftPos += 1
    else:
      rightPos -= 1

  appendOutput("Case " & $caseIndex & ": " & $pairCount & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0

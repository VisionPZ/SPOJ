{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for j in 0..<caseCount:
  let soldierCount = nextInt(inputData, scanPos)
  var walkCounts = newSeq[int](soldierCount)
  for i in 0..<soldierCount:
    walkCounts[i] = nextInt(inputData, scanPos)

  var bitTree = newSeq[int](soldierCount + 1)
  for i in 1..soldierCount:
    bitTree[i] = i and (-i)

  var highestStep = 1
  while highestStep shl 1 <= soldierCount:
    highestStep = highestStep shl 1

  var answer = newSeq[int](soldierCount)
  for i in countdown(soldierCount - 1, 0):
    var targetRank = i + 1 - walkCounts[i]
    var treePos = 0
    var l = highestStep
    while l > 0:
      let nextPos = treePos + l
      if nextPos <= soldierCount and bitTree[nextPos] < targetRank:
        treePos = nextPos
        targetRank -= bitTree[nextPos]
      l = l shr 1
    let rankValue = treePos + 1
    answer[i] = rankValue
    var k = rankValue
    while k <= soldierCount:
      bitTree[k] -= 1
      k += k and (-k)

  for i in 0..<soldierCount:
    if i > 0:
      outputBuffer.add ' '
    appendOutput($(answer[i]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

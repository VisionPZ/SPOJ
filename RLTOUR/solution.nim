const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let dollCount = nextInt(inputData, scanPos)
  var sortedHeights = newSeq[int](dollCount)
  for dollIndex in 0 .. dollCount - 1:
    sortedHeights[dollIndex] = nextInt(inputData, scanPos)
  var containersBefore = newSeq[int](dollCount)
  for dollIndex in 0 .. dollCount - 1:
    containersBefore[dollIndex] = nextInt(inputData, scanPos)
  for sortIndex in 1 .. dollCount - 1:
    let currentHeight = sortedHeights[sortIndex]
    var previousIndex = sortIndex - 1
    while previousIndex >= 0:
      if sortedHeights[previousIndex] >= currentHeight:
        break
      sortedHeights[previousIndex + 1] = sortedHeights[previousIndex]
      previousIndex -= 1
    sortedHeights[previousIndex + 1] = currentHeight
  var placedFlags = newSeq[bool](dollCount)
  var arrangement = newSeq[int](dollCount)
  var position = dollCount - 1
  while position >= 0:
    let targetCount = containersBefore[position] + 1
    var runningCount = 0
    var chosenIndex = -1
    var groupStart = 0
    while groupStart < dollCount:
      let heightValue = sortedHeights[groupStart]
      var groupEnd = groupStart
      while groupEnd < dollCount and sortedHeights[groupEnd] == heightValue:
        if not placedFlags[groupEnd]:
          runningCount += 1
        groupEnd += 1
      if chosenIndex < 0 and runningCount == targetCount:
        var candidateIndex = groupStart
        while candidateIndex < groupEnd:
          if not placedFlags[candidateIndex]:
            chosenIndex = candidateIndex
            break
          candidateIndex += 1
      groupStart = groupEnd
    placedFlags[chosenIndex] = true
    arrangement[position] = sortedHeights[chosenIndex]
    position -= 1
  for dollIndex in 0 .. dollCount - 1:
    if dollIndex > 0:
      appendOutput(" ")
    appendOutput($arrangement[dollIndex])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

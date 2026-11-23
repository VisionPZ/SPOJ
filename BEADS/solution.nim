var inputData = ""
var inputLine = ""
while stdin.readLine(inputLine):
  inputData.add(inputLine)
  inputData.add('\n')
var scanPos = 0

proc skipToLowercase() =
  while scanPos < inputData.len and (inputData[scanPos] < 'a' or inputData[scanPos] > 'z'):
    inc scanPos

proc readCaseCount(): int =
  var value = 0
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    inc scanPos
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + (ord(inputData[scanPos]) - 48)
    inc scanPos
  return value

proc readNecklace(): string =
  skipToLowercase()
  var start = scanPos
  while scanPos < inputData.len and inputData[scanPos] >= 'a' and inputData[scanPos] <= 'z':
    inc scanPos
  return inputData[start .. scanPos - 1]

proc worstDisjoinStart(beads: string): int =
  let beadCount = beads.len
  if beadCount < 2:
    return 0
  let doubled = beads & beads
  var leftIndex = 0
  var rightIndex = 1
  while leftIndex < beadCount and rightIndex < beadCount:
    var matchCount = 0
    while matchCount < beadCount and doubled[leftIndex + matchCount] == doubled[rightIndex + matchCount]:
      inc matchCount
    if matchCount >= beadCount:
      break
    if doubled[leftIndex + matchCount] > doubled[rightIndex + matchCount]:
      leftIndex = leftIndex + matchCount + 1
      if leftIndex == rightIndex:
        inc leftIndex
    else:
      rightIndex = rightIndex + matchCount + 1
      if leftIndex == rightIndex:
        inc rightIndex
  return min(leftIndex, rightIndex)

var outputBuffer = ""
const flushBlockBytes = 1 shl 18

proc flushOutput() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write(outputBuffer)
    outputBuffer.setLen(0)

let caseCount = readCaseCount()
for caseIndex in 0 ..< caseCount:
  let beads = readNecklace()
  outputBuffer.add($(worstDisjoinStart(beads) + 1))
  outputBuffer.add('\n')
  if outputBuffer.len >= flushBlockBytes:
    flushOutput()
stdout.write(outputBuffer)

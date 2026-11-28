var inputData = ""
var inputLine = ""
while stdin.readLine(inputLine):
  inputData.add(inputLine)
  inputData.add('\n')
var i = 0

proc skipToLowercase() =
  while i < inputData.len and (inputData[i] < 'a' or inputData[i] > 'z'):
    inc i

proc readCaseCount(): int =
  var value = 0
  while i < inputData.len and (inputData[i] < '0' or inputData[i] > '9'):
    inc i
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + (ord(inputData[i]) - 48)
    inc i
  return value

proc readNecklace(): string =
  skipToLowercase()
  var j = i
  while i < inputData.len and inputData[i] >= 'a' and inputData[i] <= 'z':
    inc i
  return inputData[j .. i - 1]

proc worstDisjoinStart(beads: string): int =
  let beadCount = beads.len
  if beadCount < 2:
    return 0
  let doubled = beads & beads
  var i = 0
  var j = 1
  while i < beadCount and j < beadCount:
    var matchCount = 0
    while matchCount < beadCount and doubled[i + matchCount] == doubled[j + matchCount]:
      inc matchCount
    if matchCount >= beadCount:
      break
    if doubled[i + matchCount] > doubled[j + matchCount]:
      i = i + matchCount + 1
      if i == j:
        inc i
    else:
      j = j + matchCount + 1
      if i == j:
        inc j
  return min(i, j)

var outputBuffer = ""
const flushBlockBytes = 1 shl 18

proc flushOutput() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write(outputBuffer)
    outputBuffer.setLen(0)

let caseCount = readCaseCount()
for i in 0 ..< caseCount:
  let beads = readNecklace()
  outputBuffer.add($(worstDisjoinStart(beads) + 1))
  outputBuffer.add('\n')
  if outputBuffer.len >= flushBlockBytes:
    flushOutput()
stdout.write(outputBuffer)

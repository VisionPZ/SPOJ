const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
var inputLines = newSeq[string]()
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
  inputLines.add inputLine

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

proc endsWithPattern(text: string, pattern: string): bool =
  if pattern.len > text.len:
    return false
  let startPos = text.len - pattern.len
  for patternIndex in 0 .. pattern.len - 1:
    if text[startPos + patternIndex] != pattern[patternIndex]:
      return false
  return true

let specialPattern = inputLines[0]
let fingerprintCount = nextInt(inputData, scanPos)
var matchedFingerprints = newSeq[string]()
for fingerprintIndex in 0 .. fingerprintCount - 1:
  let fingerprint = inputLines[fingerprintIndex + 2]
  if endsWithPattern(fingerprint, specialPattern):
    matchedFingerprints.add fingerprint

for sortIndex in 1 .. matchedFingerprints.len - 1:
  var cursor = sortIndex
  while cursor > 0 and matchedFingerprints[cursor] < matchedFingerprints[cursor - 1]:
    swap matchedFingerprints[cursor], matchedFingerprints[cursor - 1]
    cursor -= 1

if matchedFingerprints.len == 0:
  appendOutput("Wrong fingerprints!\n")
else:
  appendOutput($matchedFingerprints.len)
  outputBuffer.add '\n'
  for matchedFingerprint in matchedFingerprints:
    appendOutput(matchedFingerprint)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

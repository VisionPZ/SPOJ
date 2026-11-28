const flushBlockBytes = 1 shl 17
const moduloBase = 1000000007

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var firstEnd = 0
while firstEnd < inputData.len and inputData[firstEnd] != '\n':
  firstEnd += 1
let keyString = inputData[0 .. firstEnd - 1]
let secondStart = firstEnd + 1
var secondEnd = secondStart
while secondEnd < inputData.len and inputData[secondEnd] != '\n':
  secondEnd += 1
let textString = inputData[secondStart .. secondEnd - 1]
let keyLength = keyString.len

var prefixTable = newSeq[int](keyLength)
for position in 1 .. keyLength - 1:
  var backTrack = prefixTable[position - 1]
  while backTrack > 0 and keyString[position] != keyString[backTrack]:
    backTrack = prefixTable[backTrack - 1]
  if keyString[position] == keyString[backTrack]:
    backTrack += 1
  prefixTable[position] = backTrack

var occurrences = newSeq[int](0)
var matchedLength = 0
for position in 0 .. textString.len - 1:
  while matchedLength > 0 and textString[position] != keyString[matchedLength]:
    matchedLength = prefixTable[matchedLength - 1]
  if textString[position] == keyString[matchedLength]:
    matchedLength += 1
  if matchedLength == keyLength:
    occurrences.add(position - keyLength + 1)
    matchedLength = prefixTable[matchedLength - 1]

var wayCounts = newSeq[int64](occurrences.len + 1)
var lastFitting = 0
for positionIndex in 0 .. occurrences.len - 1:
  let occurrence = occurrences[positionIndex]
  while lastFitting < positionIndex and occurrences[lastFitting] + keyLength <= occurrence:
    lastFitting += 1
  wayCounts[positionIndex + 1] = (wayCounts[positionIndex] + wayCounts[lastFitting] + 1) mod moduloBase

appendOutput($wayCounts[occurrences.len])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

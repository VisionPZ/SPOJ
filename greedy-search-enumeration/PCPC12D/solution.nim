const flushBlockBytes = 1 shl 17
const firstLetterCode = 97
const upperLetterCode = 65
const lowerLetterCode = 97
const letterKinds = 26

type ProblemEntry = object
  originalName: string
  letterCounts: array[letterKinds, int]
  inputOrder: int

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

proc skipToNextLine(data: string, pos: var int) =
  while pos < data.len and data[pos] != '\n':
    pos += 1
  if pos < data.len:
    pos += 1

proc nextRawLine(data: string, pos: var int): string =
  let startPos = pos
  while pos < data.len and data[pos] != '\n':
    pos += 1
  let rawText = data[startPos ..< pos]
  if pos < data.len:
    pos += 1
  return rawText

proc compareEntries(left, right: ProblemEntry): int =
  for letterIndex in 0 ..< letterKinds:
    if left.letterCounts[letterIndex] != right.letterCounts[letterIndex]:
      if left.letterCounts[letterIndex] > right.letterCounts[letterIndex]:
        return -1
      return 1
  if left.inputOrder < right.inputOrder:
    return -1
  if left.inputOrder > right.inputOrder:
    return 1
  return 0

proc mergeSortEntries(entries: var seq[ProblemEntry], low, high: int) =
  if high - low <= 1:
    return
  let middle = (low + high) div 2
  mergeSortEntries(entries, low, middle)
  mergeSortEntries(entries, middle, high)
  var merged = newSeq[ProblemEntry](high - low)
  var leftPos = low
  var rightPos = middle
  var mergePos = 0
  while leftPos < middle and rightPos < high:
    if compareEntries(entries[leftPos], entries[rightPos]) <= 0:
      merged[mergePos] = entries[leftPos]
      leftPos += 1
    else:
      merged[mergePos] = entries[rightPos]
      rightPos += 1
    mergePos += 1
  while leftPos < middle:
    merged[mergePos] = entries[leftPos]
    leftPos += 1
    mergePos += 1
  while rightPos < high:
    merged[mergePos] = entries[rightPos]
    rightPos += 1
    mergePos += 1
  for index in 0 ..< (high - low):
    entries[low + index] = merged[index]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. testCount:
  let problemCount = nextInt(inputData, scanPos)
  skipToNextLine(inputData, scanPos)
  var entries = newSeq[ProblemEntry](problemCount)
  for problemIndex in 0 ..< problemCount:
    let rawName = nextRawLine(inputData, scanPos)
    entries[problemIndex].originalName = rawName
    entries[problemIndex].inputOrder = problemIndex
    for character in rawName:
      let characterCode = int(character)
      var lowerCode = characterCode
      if characterCode >= upperLetterCode and characterCode <= upperLetterCode + letterKinds - 1:
        lowerCode = characterCode + lowerLetterCode - upperLetterCode
      if lowerCode >= lowerLetterCode and lowerCode <= lowerLetterCode + letterKinds - 1:
        entries[problemIndex].letterCounts[lowerCode - firstLetterCode] += 1
  mergeSortEntries(entries, 0, problemCount)
  appendOutput("case: " & $caseNumber)
  outputBuffer.add '\n'
  for problemIndex in 0 ..< problemCount:
    appendOutput(entries[problemIndex].originalName)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

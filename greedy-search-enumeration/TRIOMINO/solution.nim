const flushBlockBytes = 1 shl 17
const maxBoardLength = 800

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

proc mexFrom(candidates: seq[bool]): int =
  var value = 0
  while value < candidates.len and candidates[value]:
    value += 1
  return value

var emptyRun = newSeq[int](maxBoardLength + 1)
var oneEndRun = newSeq[int](maxBoardLength + 1)
var twoEndRun = newSeq[int](maxBoardLength + 1)

for length in 1 .. maxBoardLength:
  var candidates = newSeq[bool](length + 8)
  if length >= 2:
    for leftLength in 0 .. length - 2:
      let rightLength = length - leftLength - 2
      candidates[emptyRun[leftLength] xor oneEndRun[rightLength]] = true
      candidates[oneEndRun[leftLength] xor emptyRun[rightLength]] = true
  emptyRun[length] = mexFrom(candidates)

  var oneCandidates = newSeq[bool](length + 8)
  oneCandidates[emptyRun[length - 1]] = true
  for leftLength in 0 .. length - 2:
    let rightLength = length - leftLength - 2
    oneCandidates[oneEndRun[leftLength] xor oneEndRun[rightLength]] = true
    oneCandidates[twoEndRun[leftLength] xor emptyRun[rightLength]] = true
  oneEndRun[length] = mexFrom(oneCandidates)

  var twoCandidates = newSeq[bool](length + 8)
  twoCandidates[oneEndRun[length - 1]] = true
  for leftLength in 0 .. length - 2:
    let rightLength = length - leftLength - 2
    twoCandidates[oneEndRun[leftLength] xor twoEndRun[rightLength]] = true
    twoCandidates[twoEndRun[leftLength] xor oneEndRun[rightLength]] = true
  twoEndRun[length] = mexFrom(twoCandidates)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let boardLength = nextInt(inputData, scanPos)
  if emptyRun[boardLength] == 0:
    appendOutput("Y\n")
  else:
    appendOutput("X\n")

stdout.write outputBuffer
outputBuffer.setLen 0

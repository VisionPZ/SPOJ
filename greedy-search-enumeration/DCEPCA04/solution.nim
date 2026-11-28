const flushBlockBytes = 1 shl 17
const teamCount = 100
const problemCount = 44
const selectCount = 10
const maxAccepted = teamCount * selectCount

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var problemCounts = newSeq[int](problemCount)
for teamIndex in 0 .. teamCount - 1:
  for problemIndex in 0 .. problemCount - 1:
    let solved = nextInt(inputData, scanPos)
    problemCounts[problemIndex] += solved
let threshold = nextInt(inputData, scanPos)

var ways = newSeq[seq[int64]](selectCount + 1)
for selected in 0 .. selectCount:
  ways[selected] = newSeq[int64](maxAccepted + 1)
ways[0][0] = 1
for problemIndex in 0 .. problemCount - 1:
  let acceptedCount = problemCounts[problemIndex]
  var selected = selectCount - 1
  while selected >= 0:
    for accepted in 0 .. maxAccepted - acceptedCount:
      ways[selected + 1][accepted + acceptedCount] += ways[selected][accepted]
    selected -= 1

var totalWays: int64 = 0
for accepted in 0 .. maxAccepted:
  if accepted >= threshold:
    totalWays += ways[selectCount][accepted]
appendOutput($totalWays)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

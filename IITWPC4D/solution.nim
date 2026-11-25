const flushBlockBytes = 1 shl 17

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

proc selectRank(fenwickTree: seq[int], treeSize: int, wantedRank: int): int =
  var step = 1
  while step shl 1 <= treeSize:
    step = step shl 1
  var nodeIndex = 0
  var covered = 0
  while step > 0:
    let candidate = nodeIndex + step
    if candidate <= treeSize and covered + fenwickTree[candidate] < wantedRank:
      nodeIndex = candidate
      covered += fenwickTree[candidate]
    step = step div 2
  return nodeIndex + 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let personCount = nextInt(inputData, scanPos)
  var greaterCounts = newSeq[int](personCount)
  for personIndex in 0 .. personCount - 1:
    greaterCounts[personIndex] = nextInt(inputData, scanPos)
  appendOutput("Test : " & $(caseIndex + 1))
  outputBuffer.add '\n'
  var fenwickTree = newSeq[int](personCount + 1)
  for rank in 1 .. personCount:
    fenwickTree[rank] += 1
    let parentRank = rank + (rank and -rank)
    if parentRank <= personCount:
      fenwickTree[parentRank] += fenwickTree[rank]
  var heights = newSeq[int](personCount)
  var arrangementValid = true
  var position = personCount
  while position >= 1 and arrangementValid:
    let wantedRank = position - greaterCounts[position - 1]
    if wantedRank < 1 or wantedRank > position:
      arrangementValid = false
    else:
      let chosenHeight = selectRank(fenwickTree, personCount, wantedRank)
      heights[position - 1] = chosenHeight
      var updateRank = chosenHeight
      while updateRank <= personCount:
        fenwickTree[updateRank] -= 1
        updateRank += updateRank and -updateRank
    position -= 1
  if not arrangementValid:
    appendOutput("-1")
  else:
    for personIndex in 0 .. personCount - 1:
      if personIndex > 0:
        appendOutput(" ")
      appendOutput($heights[personIndex])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

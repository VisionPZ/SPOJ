const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] != '-' and (data[pos] < '0' or data[pos] > '9')):
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

proc selectByRank(tree: seq[int], treeSize: int, topBit: int, rankValue: int): int =
  var position = 0
  var remainingRank = rankValue
  var stepValue = topBit
  while stepValue > 0:
    let candidate = position + stepValue
    if candidate <= treeSize and tree[candidate] < remainingRank:
      position = candidate
      remainingRank -= tree[candidate]
    stepValue = stepValue shr 1
  return position + 1

proc removeValue(tree: var seq[int], treeSize: int, position: int) =
  var cursor = position
  while cursor <= treeSize:
    tree[cursor] -= 1
    cursor = cursor + (cursor and (-cursor))

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while scanPos < inputData.len:
  let permutationSize = nextInt(inputData, scanPos)
  let inversionInput = nextInt(inputData, scanPos)
  if permutationSize < 0 and inversionInput < 0:
    break
  var inversionTarget = int64(inversionInput)
  var fenwickTree = newSeq[int](permutationSize + 1)
  for indexValue in 1 .. permutationSize:
    fenwickTree[indexValue] = 1
  for indexValue in 1 .. permutationSize:
    let parentIndex = indexValue + (indexValue and (-indexValue))
    if parentIndex <= permutationSize:
      fenwickTree[parentIndex] += fenwickTree[indexValue]
  var topBit = 1
  while (topBit shl 1) <= permutationSize:
    topBit = topBit shl 1
  var remainingCount = permutationSize
  while remainingCount > 0:
    let tailCapacity = int64(remainingCount - 1) * int64(remainingCount - 2) div 2
    var shiftCount = inversionTarget - tailCapacity
    if shiftCount < 0:
      shiftCount = 0
    let chosenValue = selectByRank(fenwickTree, permutationSize, topBit, int(shiftCount) + 1)
    appendOutput($chosenValue)
    if remainingCount > 1:
      appendOutput " "
    inversionTarget -= shiftCount
    removeValue(fenwickTree, permutationSize, chosenValue)
    remainingCount -= 1
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

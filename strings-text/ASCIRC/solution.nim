const firstDigitValue = 48
const firstUpperValue = 65
const firstLowerValue = 97
const registerCount = 26
const leaveCount = 26
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

proc nextInstruction(data: string, position: var int): int =
  while position < data.len and (data[position] < 'A' or data[position] > 'D'):
    position += 1
  var packed = int(data[position]) - firstUpperValue
  position += 1
  for l in 0..2:
    while position < data.len and (data[position] < 'a' or data[position] > 'z'):
      position += 1
    packed = packed * registerCount + (int(data[position]) - firstLowerValue)
    position += 1
  return packed

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
var registerValue = newSeq[int](registerCount)
var nodeOperation = newSeq[int](0)
var nodeLeft = newSeq[int](0)
var nodeRight = newSeq[int](0)
var hashSlots = newSeq[int](0)
var visited = newSeq[bool](0)
var pending = newSeq[int](0)

for i in 0..<caseCount:
  let instructionCount = nextInt(inputData, scanPos)

  for k in 0..<registerCount:
    registerValue[k] = k

  nodeOperation.setLen(0)
  nodeLeft.setLen(0)
  nodeRight.setLen(0)
  for k in 0..<leaveCount:
    nodeOperation.add(-1)
    nodeLeft.add(-1)
    nodeRight.add(-1)

  var hashSize = 1
  while hashSize < (instructionCount + leaveCount) * 4:
    hashSize = hashSize shl 1
  let hashMask = hashSize - 1
  hashSlots.setLen(hashSize)
  for k in 0..<hashSize:
    hashSlots[k] = 0

  for j in 0..<instructionCount:
    let packed = nextInstruction(inputData, scanPos)
    let destination = packed mod registerCount
    let sourceTwo = (packed div registerCount) mod registerCount
    let sourceOne = (packed div (registerCount * registerCount)) mod registerCount
    let operation = packed div (registerCount * registerCount * registerCount)
    let leftValue = registerValue[sourceOne]
    let rightValue = registerValue[sourceTwo]

    var slot = ((operation * 73856093) xor (leftValue * 19349663) xor (rightValue * 83492791)) and hashMask
    var found = -1
    while hashSlots[slot] != 0:
      let candidate = hashSlots[slot] - 1
      if nodeOperation[candidate] == operation and nodeLeft[candidate] == leftValue and nodeRight[candidate] == rightValue:
        found = candidate
        break
      slot = (slot + 1) and hashMask
    if found < 0:
      found = nodeOperation.len
      nodeOperation.add operation
      nodeLeft.add leftValue
      nodeRight.add rightValue
      hashSlots[slot] = found + 1
    registerValue[destination] = found

  visited.setLen(nodeOperation.len)
  for k in 0..<visited.len:
    visited[k] = false
  pending.setLen(0)
  for k in 0..<registerCount:
    let valueId = registerValue[k]
    if not visited[valueId]:
      visited[valueId] = true
      pending.add valueId
  var gateCount = 0
  while pending.len > 0:
    let currentNode = pending[pending.len - 1]
    pending.setLen(pending.len - 1)
    if currentNode >= leaveCount:
      gateCount += 1
      let leftChild = nodeLeft[currentNode]
      let rightChild = nodeRight[currentNode]
      if not visited[leftChild]:
        visited[leftChild] = true
        pending.add leftChild
      if not visited[rightChild]:
        visited[rightChild] = true
        pending.add rightChild

  appendOutput($(gateCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

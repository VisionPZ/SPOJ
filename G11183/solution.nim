const flushBlockBytes = 1 shl 17
const maxBlocks = 1000

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\t' or data[pos] == '\n' or data[pos] == '\r'):
    pos += 1
  if pos >= data.len:
    return ""
  let start = pos
  while pos < data.len and data[pos] != ' ' and data[pos] != '\t' and data[pos] != '\n' and data[pos] != '\r':
    pos += 1
  return data[start ..< pos]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc pileSlot(base: int, height: int): int =
  return base * maxBlocks + height

var pileContents = newSeq[int](maxBlocks * maxBlocks)
var pileSizes = newSeq[int](maxBlocks)
var blockPositions = newSeq[int](maxBlocks)
var blockDepths = newSeq[int](maxBlocks)

proc putBlockHome(blockNumber: int): int =
  let homeBase = blockNumber
  let height = pileSizes[homeBase]
  pileContents[pileSlot(homeBase, height)] = blockNumber
  pileSizes[homeBase] = height + 1
  blockPositions[blockNumber] = homeBase
  blockDepths[blockNumber] = height
  return height

proc returnBlocksAbove(base: int, height: int) =
  while pileSizes[base] > height + 1:
    let topSlot = pileSizes[base] - 1
    let movedBlock = pileContents[pileSlot(base, topSlot)]
    pileSizes[base] = topSlot
    discard putBlockHome(movedBlock)

let blockCount = nextInt(inputData, scanPos)
for base in 0 .. blockCount - 1:
  pileContents[pileSlot(base, 0)] = base
  pileSizes[base] = 1
  blockPositions[base] = base
  blockDepths[base] = 0

while true:
  let command = nextToken(inputData, scanPos)
  if command.len == 0:
    break
  if command.len == 4 and command[0] == 'q':
    break
  let isPileCommand = command.len == 4 and command[0] == 'p'
  let sourceBlock = nextInt(inputData, scanPos)
  let relation = nextToken(inputData, scanPos)
  let isOnto = relation.len == 4 and relation[1] == 'n'
  let targetBlock = nextInt(inputData, scanPos)

  var sourceBase = blockPositions[sourceBlock]
  let sourceDepth = blockDepths[sourceBlock]
  let targetBase = blockPositions[targetBlock]
  let targetDepth = blockDepths[targetBlock]

  if isPileCommand:
    if sourceBase == targetBase:
      continue
    if isOnto:
      returnBlocksAbove(targetBase, targetDepth)
    let movedCount = pileSizes[sourceBase] - sourceDepth
    let destinationBase = pileSizes[targetBase]
    var offset = 0
    while offset < movedCount:
      let movedBlock = pileContents[pileSlot(sourceBase, sourceDepth + offset)]
      pileContents[pileSlot(targetBase, destinationBase + offset)] = movedBlock
      blockPositions[movedBlock] = targetBase
      blockDepths[movedBlock] = destinationBase + offset
      offset += 1
    pileSizes[targetBase] = destinationBase + movedCount
    pileSizes[sourceBase] = sourceDepth
  else:
    returnBlocksAbove(sourceBase, sourceDepth)
    var destinationBase = targetBase
    if isOnto:
      destinationBase = blockPositions[targetBlock]
      returnBlocksAbove(destinationBase, blockDepths[targetBlock])
    sourceBase = blockPositions[sourceBlock]
    let newSourceDepth = blockDepths[sourceBlock]
    destinationBase = blockPositions[targetBlock]
    pileSizes[sourceBase] = newSourceDepth
    let newHeight = pileSizes[destinationBase]
    pileContents[pileSlot(destinationBase, newHeight)] = sourceBlock
    pileSizes[destinationBase] = newHeight + 1
    blockPositions[sourceBlock] = destinationBase
    blockDepths[sourceBlock] = newHeight

for base in 0 .. blockCount - 1:
  appendOutput($base)
  appendOutput(":")
  var height = 0
  while height < pileSizes[base]:
    appendOutput(" ")
    appendOutput($pileContents[pileSlot(base, height)])
    height += 1
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0

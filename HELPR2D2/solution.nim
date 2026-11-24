const
  maxShips = 100000
  treeSize = 1 shl 17
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18

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

proc skipSpaces(data: string, position: var int) =
  while position < data.len and data[position] <= ' ':
    position += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var tree: array[2 * treeSize, int]
var remainingCapacity: array[maxShips + 4, int]
var shipCount = 0
var capacity = 0

proc updateCapacity(shipIndex: int, value: int) =
  var node = treeSize + shipIndex
  tree[node] = value
  while node > 1:
    node = node shr 1
    let leftChild = node shl 1
    let rightChild = leftChild or 1
    let leftValue = tree[leftChild]
    let rightValue = tree[rightChild]
    tree[node] = if leftValue >= rightValue: leftValue else: rightValue

proc leftmostFitting(threshold: int): int =
  if tree[1] < threshold:
    return -1
  var node = 1
  while node < treeSize:
    let leftChild = node shl 1
    if tree[leftChild] >= threshold:
      node = leftChild
    else:
      node = leftChild or 1
  return node - treeSize

proc placeContainers(repeatCount: int, blockVolume: int) =
  var remaining = repeatCount
  while remaining > 0:
    var shipIndex = leftmostFitting(blockVolume)
    if shipIndex < 0:
      let perShip = capacity div blockVolume
      while remaining > 0:
        let take = if remaining < perShip: remaining else: perShip
        remainingCapacity[shipCount] = capacity - take * blockVolume
        updateCapacity(shipCount, remainingCapacity[shipCount])
        shipCount += 1
        remaining -= take
      return
    while remaining > 0 and shipIndex < shipCount:
      let fitCount = remainingCapacity[shipIndex] div blockVolume
      if fitCount == 0:
        shipIndex += 1
      else:
        let take = if remaining < fitCount: remaining else: fitCount
        remainingCapacity[shipIndex] -= take * blockVolume
        updateCapacity(shipIndex, remainingCapacity[shipIndex])
        remaining -= take
        if remaining > 0:
          shipIndex += 1

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  capacity = nextInt(inputData, scanPos)
  let containerCount = nextInt(inputData, scanPos)
  for index in 0..<tree.len:
    tree[index] = 0
  shipCount = 0
  var processed = 0
  while processed < containerCount:
    skipSpaces(inputData, scanPos)
    if scanPos < inputData.len and (inputData[scanPos] == 'b' or inputData[scanPos] == 'B'):
      scanPos += 1
      let repeatCount = nextInt(inputData, scanPos)
      let blockVolume = nextInt(inputData, scanPos)
      placeContainers(repeatCount, blockVolume)
      processed += repeatCount
    else:
      let singleVolume = nextInt(inputData, scanPos)
      placeContainers(1, singleVolume)
      processed += 1
  var totalWaste: int64 = 0
  for index in 0..<shipCount:
    totalWaste += int64(remainingCapacity[index])
  appendOutput($shipCount & " " & $totalWaste)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

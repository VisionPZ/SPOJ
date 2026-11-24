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

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

proc skipSpaces(data: string, i: var int) =
  while i < data.len and data[i] <= ' ':
    i += 1

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

proc updateCapacity(i: int, value: int) =
  var node = treeSize + i
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
    var i = leftmostFitting(blockVolume)
    if i < 0:
      let perShip = capacity div blockVolume
      while remaining > 0:
        let take = if remaining < perShip: remaining else: perShip
        remainingCapacity[shipCount] = capacity - take * blockVolume
        updateCapacity(shipCount, remainingCapacity[shipCount])
        shipCount += 1
        remaining -= take
      return
    while remaining > 0 and i < shipCount:
      let fitCount = remainingCapacity[i] div blockVolume
      if fitCount == 0:
        i += 1
      else:
        let take = if remaining < fitCount: remaining else: fitCount
        remainingCapacity[i] -= take * blockVolume
        updateCapacity(i, remainingCapacity[i])
        remaining -= take
        if remaining > 0:
          i += 1

let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  capacity = nextInt(inputData, i)
  let containerCount = nextInt(inputData, i)
  for k in 0..<tree.len:
    tree[k] = 0
  shipCount = 0
  var processed = 0
  while processed < containerCount:
    skipSpaces(inputData, i)
    if i < inputData.len and (inputData[i] == 'b' or inputData[i] == 'B'):
      i += 1
      let repeatCount = nextInt(inputData, i)
      let blockVolume = nextInt(inputData, i)
      placeContainers(repeatCount, blockVolume)
      processed += repeatCount
    else:
      let singleVolume = nextInt(inputData, i)
      placeContainers(1, singleVolume)
      processed += 1
  var totalWaste: int64 = 0
  for k in 0..<shipCount:
    totalWaste += int64(remainingCapacity[k])
  appendOutput($shipCount & " " & $totalWaste)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

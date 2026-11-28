import algorithm

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let coinCount = nextInt(inputData, scanPos)
var tnValues = newSeq[int](coinCount)
var dbValues = newSeq[int64](coinCount)
for coinIndex in 0 .. coinCount - 1:
  tnValues[coinIndex] = nextInt(inputData, scanPos)
for coinIndex in 0 .. coinCount - 1:
  dbValues[coinIndex] = int64(nextInt(inputData, scanPos))

var sortedCoins = newSeq[int](coinCount)
for coinIndex in 0 .. coinCount - 1:
  sortedCoins[coinIndex] = coinIndex
sortedCoins.sort(proc(leftCoin, rightCoin: int): int =
  if tnValues[leftCoin] > tnValues[rightCoin]: return -1
  if tnValues[leftCoin] < tnValues[rightCoin]: return 1
  return 0)

var heapValues = newSeq[int64](coinCount + 1)
var heapCoins = newSeq[int](coinCount + 1)
var heapSize = 0

proc heapPush(value: int64, coinIndex: int) =
  heapSize += 1
  heapValues[heapSize] = value
  heapCoins[heapSize] = coinIndex
  var childIndex = heapSize
  while childIndex > 1:
    let parentIndex = childIndex div 2
    if heapValues[parentIndex] <= heapValues[childIndex]:
      break
    swap heapValues[parentIndex], heapValues[childIndex]
    swap heapCoins[parentIndex], heapCoins[childIndex]
    childIndex = parentIndex

proc heapPop(): int =
  let poppedCoin = heapCoins[1]
  heapValues[1] = heapValues[heapSize]
  heapCoins[1] = heapCoins[heapSize]
  heapSize -= 1
  var parentIndex = 1
  while true:
    let leftChild = parentIndex * 2
    if leftChild > heapSize:
      break
    let rightChild = leftChild + 1
    var smallerChild = leftChild
    if rightChild <= heapSize and heapValues[rightChild] < heapValues[leftChild]:
      smallerChild = rightChild
    if heapValues[parentIndex] <= heapValues[smallerChild]:
      break
    swap heapValues[parentIndex], heapValues[smallerChild]
    swap heapCoins[parentIndex], heapCoins[smallerChild]
    parentIndex = smallerChild
  return poppedCoin

var keepsDb = newSeq[bool](coinCount)
var dbTotal: int64 = 0
var dbCount = 0
var tnCount = 0
for orderIndex in 0 .. coinCount - 1:
  let currentCoin = sortedCoins[orderIndex]
  heapPush(dbValues[currentCoin], currentCoin)
  dbTotal = dbTotal + dbValues[currentCoin]
  dbCount += 1
  keepsDb[currentCoin] = true
  if dbCount > tnCount:
    let droppedCoin = heapPop()
    keepsDb[droppedCoin] = false
    dbTotal = dbTotal - dbValues[droppedCoin]
    dbCount -= 1
    tnCount += 1

var dbCoins = newSeq[int](dbCount)
var tnCoins = newSeq[int](tnCount)
var dbCursor = 0
var tnCursor = 0
var reverseIndex = coinCount - 1
while reverseIndex >= 0:
  let currentCoin = sortedCoins[reverseIndex]
  if keepsDb[currentCoin]:
    dbCoins[dbCursor] = currentCoin
    dbCursor += 1
  else:
    tnCoins[tnCursor] = currentCoin
    tnCursor += 1
  reverseIndex -= 1

appendOutput($dbTotal)
outputBuffer.add '\n'
for pairIndex in 0 .. dbCount - 1:
  appendOutput($(dbCoins[pairIndex] + 1))
  outputBuffer.add ' '
  appendOutput($(tnCoins[pairIndex] + 1))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

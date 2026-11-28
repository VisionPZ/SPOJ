import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxBoxSize = 1000

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var boxValues: array[maxBoxSize + 1, seq[int]]
var needCount: array[maxBoxSize + 1, int]
var visitMark: array[maxBoxSize + 1, int]
var currentMark = 0
var touchedSizes: seq[int] = @[]

proc touch(size: int) =
  if visitMark[size] != currentMark:
    visitMark[size] = currentMark
    touchedSizes.add size

proc resetCase() =
  for size in touchedSizes:
    boxValues[size].setLen 0
    needCount[size] = 0
  touchedSizes.setLen 0
  currentMark += 1

proc byValue(leftValue, rightValue: int): int =
  result = system.cmp(leftValue, rightValue)

let caseCount = nextInt(inputData, scanPos)
for i in 0..<caseCount:
  resetCase()
  var topSize = 0
  let boxTotal = nextInt(inputData, scanPos)
  for j in 0..<boxTotal:
    let size = nextInt(inputData, scanPos)
    let value = nextInt(inputData, scanPos)
    touch(size)
    boxValues[size].add value
    if size > topSize:
      topSize = size
  let kindCount = nextInt(inputData, scanPos)
  for k in 0..<kindCount:
    let size = nextInt(inputData, scanPos)
    let count = nextInt(inputData, scanPos)
    touch(size)
    needCount[size] = count
    if size > topSize:
      topSize = size

  var pool: seq[int] = @[]
  var total: int = 0
  var feasible = true
  for size in 0..topSize:
    for value in boxValues[size]:
      pool.add value
    pool.sort(byValue)
    let need = needCount[size]
    if need > pool.len:
      feasible = false
      break
    for l in 0..<need:
      total += pool[l]
    let restCount = pool.len - need
    var nextPool: seq[int] = @[]
    nextPool.setLen restCount div 2
    for m in 0..<(restCount div 2):
      nextPool[m] = pool[need + 2 * m] + pool[need + 2 * m + 1]
    pool = nextPool

  if feasible:
    appendOutput($total)
  else:
    appendOutput("No")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

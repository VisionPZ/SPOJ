const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const cellTotal = 56
const rowWidth = 8
const rowTotal = 7
const dominoTotal = 28
const labelTotal = 7
const perLabelCount = 8
const maxNeighbors = 4

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var cellMask: array[cellTotal, int]
var allCellsMask = 0
var dominoMask: array[dominoTotal, int]
var neighborCount: array[cellTotal, int]
var neighborCell: array[cellTotal, array[maxNeighbors, int]]
var neighborDomino: array[cellTotal, array[maxNeighbors, int]]
var neighborMask: array[cellTotal, array[maxNeighbors, int]]
var cellLabel: array[cellTotal, int]

proc dominoIndex(low: int, high: int): int =
  return low * labelTotal + high - (low * (low + 1)) div 2

proc prepareStatic() =
  for cellIdx in 0 ..< cellTotal:
    cellMask[cellIdx] = 1 shl cellIdx
    allCellsMask = allCellsMask or cellMask[cellIdx]
  for dominoIdx in 0 ..< dominoTotal:
    dominoMask[dominoIdx] = 1 shl dominoIdx
  for cellIdx in 0 ..< cellTotal:
    let row = cellIdx div rowWidth
    let col = cellIdx mod rowWidth
    var count = 0
    if col + 1 < rowWidth:
      neighborCell[cellIdx][count] = cellIdx + 1
      count += 1
    if row + 1 < rowTotal:
      neighborCell[cellIdx][count] = cellIdx + rowWidth
      count += 1
    if col > 0:
      neighborCell[cellIdx][count] = cellIdx - 1
      count += 1
    if row > 0:
      neighborCell[cellIdx][count] = cellIdx - rowWidth
      count += 1
    neighborCount[cellIdx] = count
    for neighborIdx in 0 ..< count:
      let adjCell = neighborCell[cellIdx][neighborIdx]
      neighborMask[cellIdx][neighborIdx] = cellMask[cellIdx] or cellMask[adjCell]

proc prepareLabels() =
  for cellIdx in 0 ..< cellTotal:
    for neighborIdx in 0 ..< neighborCount[cellIdx]:
      let adjCell = neighborCell[cellIdx][neighborIdx]
      let low = cellLabel[cellIdx]
      let high = cellLabel[adjCell]
      if low <= high:
        neighborDomino[cellIdx][neighborIdx] = dominoIndex(low, high)
      else:
        neighborDomino[cellIdx][neighborIdx] = dominoIndex(high, low)

var answerCount: int64

proc search(covered: int, usedDomino: int) =
  if covered == allCellsMask:
    answerCount += 1
    return
  var bestCell = -1
  var bestCount = maxNeighbors + 1
  for cellIdx in 0 ..< cellTotal:
    if (covered and cellMask[cellIdx]) != 0:
      continue
    var count = 0
    for neighborIdx in 0 ..< neighborCount[cellIdx]:
      if (covered and cellMask[neighborCell[cellIdx][neighborIdx]]) != 0:
        continue
      if (usedDomino and dominoMask[neighborDomino[cellIdx][neighborIdx]]) == 0:
        count += 1
    if count < bestCount:
      bestCount = count
      bestCell = cellIdx
      if count == 0:
        break
  if bestCount == 0:
    return
  for neighborIdx in 0 ..< neighborCount[bestCell]:
    let adjCell = neighborCell[bestCell][neighborIdx]
    if (covered and cellMask[adjCell]) != 0:
      continue
    let used = dominoMask[neighborDomino[bestCell][neighborIdx]]
    if (usedDomino and used) == 0:
      search(covered or neighborMask[bestCell][neighborIdx], usedDomino or used)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

prepareStatic()
let caseCount = nextInt(inputData, scanPos)
for caseIdx in 0 ..< caseCount:
  for cellIdx in 0 ..< cellTotal:
    cellLabel[cellIdx] = nextInt(inputData, scanPos)
  var labelCount: array[labelTotal, int]
  for cellIdx in 0 ..< cellTotal:
    labelCount[cellLabel[cellIdx]] += 1
  var possible = true
  for labelIdx in 0 ..< labelTotal:
    if labelCount[labelIdx] != perLabelCount:
      possible = false
  if not possible:
    appendOutput("0")
  else:
    prepareLabels()
    answerCount = 0
    search(0, 0)
    appendOutput($(answerCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

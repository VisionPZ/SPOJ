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
  for p in 0 ..< cellTotal:
    cellMask[p] = 1 shl p
    allCellsMask = allCellsMask or cellMask[p]
  for d in 0 ..< dominoTotal:
    dominoMask[d] = 1 shl d
  for p in 0 ..< cellTotal:
    let row = p div rowWidth
    let col = p mod rowWidth
    var count = 0
    if col + 1 < rowWidth:
      neighborCell[p][count] = p + 1
      count += 1
    if row + 1 < rowTotal:
      neighborCell[p][count] = p + rowWidth
      count += 1
    if col > 0:
      neighborCell[p][count] = p - 1
      count += 1
    if row > 0:
      neighborCell[p][count] = p - rowWidth
      count += 1
    neighborCount[p] = count
    for k in 0 ..< count:
      let q = neighborCell[p][k]
      neighborMask[p][k] = cellMask[p] or cellMask[q]

proc prepareLabels() =
  for p in 0 ..< cellTotal:
    for k in 0 ..< neighborCount[p]:
      let q = neighborCell[p][k]
      let low = cellLabel[p]
      let high = cellLabel[q]
      if low <= high:
        neighborDomino[p][k] = dominoIndex(low, high)
      else:
        neighborDomino[p][k] = dominoIndex(high, low)

var answerCount: int64

proc search(covered: int, usedDomino: int) =
  if covered == allCellsMask:
    answerCount += 1
    return
  var bestCell = -1
  var bestCount = maxNeighbors + 1
  for p in 0 ..< cellTotal:
    if (covered and cellMask[p]) != 0:
      continue
    var count = 0
    for k in 0 ..< neighborCount[p]:
      if (covered and cellMask[neighborCell[p][k]]) != 0:
        continue
      if (usedDomino and dominoMask[neighborDomino[p][k]]) == 0:
        count += 1
    if count < bestCount:
      bestCount = count
      bestCell = p
      if count == 0:
        break
  if bestCount == 0:
    return
  for k in 0 ..< neighborCount[bestCell]:
    let q = neighborCell[bestCell][k]
    if (covered and cellMask[q]) != 0:
      continue
    let used = dominoMask[neighborDomino[bestCell][k]]
    if (usedDomino and used) == 0:
      search(covered or neighborMask[bestCell][k], usedDomino or used)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

prepareStatic()
let caseCount = nextInt(inputData, scanPos)
for caseIdx in 0 ..< caseCount:
  for p in 0 ..< cellTotal:
    cellLabel[p] = nextInt(inputData, scanPos)
  var labelCount: array[labelTotal, int]
  for p in 0 ..< cellTotal:
    labelCount[cellLabel[p]] += 1
  var possible = true
  for l in 0 ..< labelTotal:
    if labelCount[l] != perLabelCount:
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

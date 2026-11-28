import algorithm

const flushBlockBytes = 1 shl 17
const impossibleLength = -1000000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
let cellCount = rowCount * columnCount
var heights = newSeq[int](cellCount)
for cellIndex in 0 .. cellCount - 1:
  heights[cellIndex] = nextInt(inputData, scanPos)

var orderedCells = newSeq[int](cellCount)
for cellIndex in 0 .. cellCount - 1:
  orderedCells[cellIndex] = cellIndex
orderedCells.sort(proc(leftCell, rightCell: int): int =
  if heights[leftCell] < heights[rightCell]: -1
  elif heights[leftCell] > heights[rightCell]: 1
  else: 0)

var heightRank = newSeq[int](cellCount)
for rankIndex in 0 .. cellCount - 1:
  heightRank[orderedCells[rankIndex]] = rankIndex

var downhillNeighbors = newSeq[seq[int]](cellCount)
for rowIndex in 0 .. rowCount - 1:
  for columnIndex in 0 .. columnCount - 1:
    let cellIndex = rowIndex * columnCount + columnIndex
    for directionIndex in 0 .. 3:
      var neighborRow = rowIndex
      var neighborColumn = columnIndex
      if directionIndex == 0:
        neighborRow += 1
      elif directionIndex == 1:
        neighborColumn += 1
      elif directionIndex == 2:
        neighborRow -= 1
      else:
        neighborColumn -= 1
      if neighborRow < 0 or neighborRow >= rowCount or
         neighborColumn < 0 or neighborColumn >= columnCount:
        continue
      let neighborIndex = neighborRow * columnCount + neighborColumn
      if heights[neighborIndex] < heights[cellIndex]:
        downhillNeighbors[heightRank[cellIndex]].add(heightRank[neighborIndex])

var valleyLengths = newSeq[int](cellCount * cellCount)
var predecessors = newSeq[int](cellCount * cellCount)
for stateIndex in 0 .. cellCount * cellCount - 1:
  valleyLengths[stateIndex] = impossibleLength
  predecessors[stateIndex] = 0

var bestLength = 1
var bestFirstRank = 0
var bestSecondRank = 0

for firstRank in 0 .. cellCount - 1:
  valleyLengths[firstRank * cellCount + firstRank] = 1
  for secondRank in firstRank + 1 .. cellCount - 1:
    for lowerRank in downhillNeighbors[secondRank]:
      var leftRank = firstRank
      var rightRank = lowerRank
      if leftRank > rightRank:
        swap(leftRank, rightRank)
      let candidate = 1 + valleyLengths[leftRank * cellCount + rightRank]
      if candidate > valleyLengths[firstRank * cellCount + secondRank]:
        valleyLengths[firstRank * cellCount + secondRank] = candidate
        predecessors[firstRank * cellCount + secondRank] = lowerRank
        if candidate > bestLength:
          bestLength = candidate
          bestFirstRank = firstRank
          bestSecondRank = secondRank

var firstBranch = newSeq[int]()
var secondBranch = newSeq[int]()
firstBranch.add(orderedCells[bestFirstRank])
secondBranch.add(orderedCells[bestSecondRank])
var leftRank = bestFirstRank
var rightRank = bestSecondRank
while leftRank != rightRank:
  if leftRank > rightRank:
    swap(leftRank, rightRank)
    swap(firstBranch, secondBranch)
  rightRank = predecessors[leftRank * cellCount + rightRank]
  secondBranch.add(orderedCells[rightRank])

var valleyPath = newSeq[int]()
for cellIndex in firstBranch:
  valleyPath.add cellIndex
var reverseIndex = secondBranch.len - 2
while reverseIndex >= 0:
  valleyPath.add secondBranch[reverseIndex]
  reverseIndex -= 1
if heights[valleyPath[0]] > heights[valleyPath[valleyPath.len - 1]]:
  var reversedPath = newSeq[int]()
  reverseIndex = valleyPath.len - 1
  while reverseIndex >= 0:
    reversedPath.add valleyPath[reverseIndex]
    reverseIndex -= 1
  valleyPath = reversedPath

appendOutput($bestLength)
outputBuffer.add '\n'
for cellIndex in valleyPath:
  appendOutput($(cellIndex div columnCount + 1))
  appendOutput(" ")
  appendOutput($(cellIndex mod columnCount + 1))
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0

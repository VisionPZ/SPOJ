const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const directionOffset = 200
const directionWidth = 401
const directionTableSize = directionWidth * directionWidth
const infiniteCross = 1 shl 60
const successSentence = "The shortest path is "
const failureSentence = "Mission impossible!"
const stepSuffix = " steps long."

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
    value = value * 10 + (int(data[position]) - firstDigitValue)
    position += 1
  return value

proc greatestCommonDivisor(first: int, second: int): int =
  var left = first
  var right = second
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  return left

var directionMaxSteps = newSeq[int](directionTableSize)
var usedDirections: seq[int] = @[]

proc markVisibleFromSource(terrain: seq[int], rowCount: int, colCount: int,
                           sourceRow: int, sourceCol: int,
                           visible: var seq[bool]) =
  let sourceHeight = 2 * terrain[sourceRow * colCount + sourceCol] + 1
  usedDirections.setLen 0
  for row in 0..<rowCount:
    for col in 0..<colCount:
      if row == sourceRow and col == sourceCol:
        continue
      let colGap = col - sourceCol
      let rowGap = row - sourceRow
      let steps = greatestCommonDivisor(abs(colGap), abs(rowGap))
      let dirCol = colGap div steps
      let dirRow = rowGap div steps
      let dirIndex = (dirCol + directionOffset) * directionWidth + dirRow + directionOffset
      if directionMaxSteps[dirIndex] == 0:
        usedDirections.add dirIndex
      if steps > directionMaxSteps[dirIndex]:
        directionMaxSteps[dirIndex] = steps
  visible[sourceRow * colCount + sourceCol] = true
  for dirIndex in usedDirections:
    let dirCol = dirIndex div directionWidth - directionOffset
    let dirRow = dirIndex mod directionWidth - directionOffset
    let stepX = if dirCol == 0: 1 else: 2 * abs(dirCol)
    let stepY = if dirRow == 0: 1 else: 2 * abs(dirRow)
    let scale = stepX * stepY
    let maxSteps = directionMaxSteps[dirIndex]
    var nextCrossX = if dirCol == 0: infiniteCross else: stepY
    var nextCrossY = if dirRow == 0: infiniteCross else: stepX
    let advanceX = 2 * stepY
    let advanceY = 2 * stepX
    let signX = if dirCol > 0: 1 else: -1
    let signY = if dirRow > 0: 1 else: -1
    var currentRow = sourceRow
    var currentCol = sourceCol
    var previousCross = 0
    var hasAscending = false
    var hasDescending = false
    var ascendingNum = 0
    var ascendingDen = 1
    var descendingNum = 0
    var descendingDen = 1
    for step in 1..maxSteps:
      let centerCross = step * scale
      while nextCrossX < centerCross or nextCrossY < centerCross:
        let cellCross = min(nextCrossX, nextCrossY)
        let currentHeight = 2 * terrain[currentRow * colCount + currentCol] - sourceHeight
        let leavingCandidate = currentHeight * scale
        if not hasDescending or leavingCandidate * descendingDen > descendingNum * cellCross:
          hasDescending = true
          descendingNum = leavingCandidate
          descendingDen = cellCross
        if nextCrossX == cellCross:
          currentCol += signX
          nextCrossX += advanceX
        if nextCrossY == cellCross:
          currentRow += signY
          nextCrossY += advanceY
        previousCross = cellCross
        let nextHeight = 2 * terrain[currentRow * colCount + currentCol] - sourceHeight
        let enteringCandidate = nextHeight * scale
        if previousCross > 0 and (not hasAscending or
            enteringCandidate * ascendingDen > ascendingNum * previousCross):
          hasAscending = true
          ascendingNum = enteringCandidate
          ascendingDen = previousCross
      let targetRow = sourceRow + step * dirRow
      let targetCol = sourceCol + step * dirCol
      let targetHeight = 2 * terrain[targetRow * colCount + targetCol] + 1
      let targetSlope = targetHeight - sourceHeight
      var isVisible = false
      if targetSlope >= 0:
        isVisible = not hasAscending or
                    targetSlope * ascendingDen >= ascendingNum * step
      else:
        isVisible = not hasDescending or
                    targetSlope * descendingDen >= descendingNum * step
      if isVisible:
        visible[targetRow * colCount + targetCol] = true
    directionMaxSteps[dirIndex] = 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 1..testCount:
  let rowCount = nextInt(inputData, scanPos)
  let colCount = nextInt(inputData, scanPos)
  var terrain = newSeq[int](rowCount * colCount)
  for cellIndex in 0..<rowCount * colCount:
    terrain[cellIndex] = nextInt(inputData, scanPos)
  let firstRow = nextInt(inputData, scanPos) - 1
  let firstCol = nextInt(inputData, scanPos) - 1
  let secondRow = nextInt(inputData, scanPos) - 1
  let secondCol = nextInt(inputData, scanPos) - 1
  let firstIndex = firstRow * colCount + firstCol
  let secondIndex = secondRow * colCount + secondCol
  var visible = newSeq[bool](rowCount * colCount)
  markVisibleFromSource(terrain, rowCount, colCount, firstRow, firstCol, visible)
  markVisibleFromSource(terrain, rowCount, colCount, secondRow, secondCol, visible)
  var distance = newSeq[int](rowCount * colCount)
  for cellIndex in 0..<rowCount * colCount:
    distance[cellIndex] = -1
  var queue = newSeq[int](rowCount * colCount)
  var queueHead = 0
  var queueTail = 0
  distance[firstIndex] = 0
  queue[queueTail] = firstIndex
  queueTail += 1
  while queueHead < queueTail and distance[secondIndex] == -1:
    let current = queue[queueHead]
    queueHead += 1
    let currentRow = current div colCount
    let currentCol = current mod colCount
    let currentHeight = terrain[current]
    for neighborIndex in 0..<4:
      var neighborRow = currentRow
      var neighborCol = currentCol
      case neighborIndex
      of 0: neighborRow -= 1
      of 1: neighborRow += 1
      of 2: neighborCol -= 1
      else: neighborCol += 1
      if neighborRow < 0 or neighborRow >= rowCount or neighborCol < 0 or neighborCol >= colCount:
        continue
      let neighbor = neighborRow * colCount + neighborCol
      if distance[neighbor] != -1 or not visible[neighbor]:
        continue
      let neighborHeight = terrain[neighbor]
      if neighborHeight - currentHeight > 1 or currentHeight - neighborHeight > 3:
        continue
      distance[neighbor] = distance[current] + 1
      queue[queueTail] = neighbor
      queueTail += 1
  if distance[secondIndex] == -1:
    appendOutput(failureSentence)
  else:
    appendOutput(successSentence)
    appendOutput($distance[secondIndex])
    appendOutput(stepSuffix)
  appendOutput("\n")

stdout.write outputBuffer

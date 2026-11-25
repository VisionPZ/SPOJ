import tables

const flushBlockBytes = 1 shl 17
const nibbleMask: int64 = 15
const nibbleBits = 4
const unreachable = 1 shl 28

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

proc nextMapChar(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = data[pos]
  pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var digitRows = newSeq[int]()
var digitColumns = newSeq[int]()
var digitTargets = newSeq[int]()
var candidateRows = newSeq[int]()
var candidateColumns = newSeq[int]()
var affectsDigit = newSeq[seq[bool]]()
var remainingPossible = newSeq[seq[int]]()
var memoResults = newSeq[Table[int64, int]]()

proc searchChests(cellIndex: int, state: int64): int =
  var allSatisfied = true
  for digitIndex in 0 .. digitTargets.len - 1:
    if ((state shr (nibbleBits * digitIndex)) and nibbleMask) != 0:
      allSatisfied = false
      break
  if allSatisfied:
    return 0
  if cellIndex == candidateRows.len:
    return unreachable
  if memoResults[cellIndex].hasKey(state):
    return memoResults[cellIndex][state]
  for digitIndex in 0 .. digitTargets.len - 1:
    let remaining = int((state shr (nibbleBits * digitIndex)) and nibbleMask)
    if remaining > remainingPossible[digitIndex][cellIndex]:
      memoResults[cellIndex][state] = unreachable
      return unreachable
  var bestPlacement = searchChests(cellIndex + 1, state)
  var mayPlace = true
  for digitIndex in 0 .. digitTargets.len - 1:
    if affectsDigit[digitIndex][cellIndex] and
       ((state shr (nibbleBits * digitIndex)) and nibbleMask) == 0:
      mayPlace = false
      break
  if mayPlace:
    var nextState = state
    for digitIndex in 0 .. digitTargets.len - 1:
      if affectsDigit[digitIndex][cellIndex]:
        nextState = nextState - (int64(1) shl (nibbleBits * digitIndex))
    bestPlacement = min(bestPlacement, 1 + searchChests(cellIndex + 1, nextState))
  memoResults[cellIndex][state] = bestPlacement
  return bestPlacement

while true:
  let mapHeight = nextInt(inputData, scanPos)
  let mapWidth = nextInt(inputData, scanPos)
  if mapHeight == 0 and mapWidth == 0:
    break
  var mapRows = newSeq[string](mapHeight)
  for rowIndex in 0 .. mapHeight - 1:
    var rowText = ""
    for columnIndex in 0 .. mapWidth - 1:
      rowText.add nextMapChar(inputData, scanPos)
    mapRows[rowIndex] = rowText
  digitRows.setLen 0
  digitColumns.setLen 0
  digitTargets.setLen 0
  for rowIndex in 0 .. mapHeight - 1:
    for columnIndex in 0 .. mapWidth - 1:
      let sectionChar = mapRows[rowIndex][columnIndex]
      if sectionChar >= '0' and sectionChar <= '9':
        digitRows.add rowIndex
        digitColumns.add columnIndex
        digitTargets.add int(sectionChar) - 48
  candidateRows.setLen 0
  candidateColumns.setLen 0
  for rowIndex in 0 .. mapHeight - 1:
    for columnIndex in 0 .. mapWidth - 1:
      if mapRows[rowIndex][columnIndex] == '.':
        continue
      var touchesDigit = false
      for digitIndex in 0 .. digitRows.len - 1:
        if abs(rowIndex - digitRows[digitIndex]) <= 1 and
           abs(columnIndex - digitColumns[digitIndex]) <= 1:
          touchesDigit = true
          break
      if touchesDigit:
        candidateRows.add rowIndex
        candidateColumns.add columnIndex
  let candidateCount = candidateRows.len
  affectsDigit = newSeq[seq[bool]]()
  remainingPossible = newSeq[seq[int]]()
  for digitIndex in 0 .. digitRows.len - 1:
    var digitAffects = newSeq[bool](candidateCount)
    for cellIndex in 0 .. candidateCount - 1:
      if abs(candidateRows[cellIndex] - digitRows[digitIndex]) <= 1 and
         abs(candidateColumns[cellIndex] - digitColumns[digitIndex]) <= 1:
        digitAffects[cellIndex] = true
    affectsDigit.add digitAffects
    var possibleCounts = newSeq[int](candidateCount + 1)
    var reverseIndex = candidateCount - 1
    while reverseIndex >= 0:
      possibleCounts[reverseIndex] = possibleCounts[reverseIndex + 1]
      if digitAffects[reverseIndex]:
        possibleCounts[reverseIndex] += 1
      reverseIndex -= 1
    remainingPossible.add possibleCounts
  memoResults = newSeq[Table[int64, int]](candidateCount + 1)
  for memoIndex in 0 .. candidateCount:
    memoResults[memoIndex] = initTable[int64, int]()
  var initialState: int64 = 0
  for digitIndex in 0 .. digitTargets.len - 1:
    initialState = initialState or (int64(digitTargets[digitIndex]) shl (nibbleBits * digitIndex))
  let minimumChests = searchChests(0, initialState)
  appendOutput($minimumChests)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0

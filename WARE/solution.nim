const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const cellsPerWord = 16
const bitsPerCell = 4
const cellMask = 15'u64
const markerOffset = 6
const emptyCell = 0
const fallenCell = 1
const exitCell = 5
const directionRows = [1, -1, 0, 0]
const directionColumns = [0, 0, 1, -1]

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

proc nextCellChar(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let foundChar = data[pos]
  pos += 1
  return foundChar

proc mixWord(wordValue: uint64): uint64 =
  var mixed = wordValue
  mixed = mixed xor (mixed shr 30)
  mixed = mixed * 0xbf58476d1ce4e5b9'u64
  mixed = mixed xor (mixed shr 27)
  mixed = mixed * 0x94d049bb133111eb'u64
  mixed = mixed xor (mixed shr 31)
  return mixed

proc cellCode(cells: array[4, uint64], index: int): int =
  let wordIndex = index div cellsPerWord
  let shiftAmount = (index mod cellsPerWord) * bitsPerCell
  return int((cells[wordIndex] shr uint(shiftAmount)) and cellMask)

proc setCellCode(cells: var array[4, uint64], index: int, code: int) =
  let wordIndex = index div cellsPerWord
  let shiftAmount = uint((index mod cellsPerWord) * bitsPerCell)
  let cleared = cells[wordIndex] and not (cellMask shl shiftAmount)
  cells[wordIndex] = cleared or (uint64(code) shl shiftAmount)

proc underlyingCode(code: int): int =
  if code > exitCell: return code - markerOffset
  return code

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let boardSize = nextInt(inputData, scanPos)
  let startRow = nextInt(inputData, scanPos) - 1
  let startColumn = nextInt(inputData, scanPos) - 1
  if boardSize == 0 and startRow == -1 and startColumn == -1:
    break
  var startCells: array[4, uint64]
  for cellIndex in 0 .. boardSize * boardSize - 1:
    let cellChar = nextCellChar(inputData, scanPos)
    var code = emptyCell
    case cellChar
    of '2': code = 2
    of '3': code = 3
    of '4': code = 4
    of 'E': code = exitCell
    else: code = emptyCell
    setCellCode(startCells, cellIndex, code)
  var startPosition = startRow * boardSize + startColumn
  let standingCode = cellCode(startCells, startPosition)
  if standingCode != emptyCell:
    setCellCode(startCells, startPosition, standingCode + markerOffset)
  var tableCapacity = 1 shl 14
  var seenWords = newSeq[uint64](tableCapacity * 4)
  var seenUsed = newSeq[bool](tableCapacity)
  var usedCount = 0

  proc findSlot(cells: array[4, uint64]): int =
    var hashValue = mixWord(cells[0])
    for wordIndex in 1 .. 3:
      hashValue = hashValue xor mixWord(cells[wordIndex] + hashValue)
    var slotIndex = int(hashValue and uint64(tableCapacity - 1))
    while seenUsed[slotIndex]:
      var matches = true
      for wordIndex in 0 .. 3:
        if seenWords[slotIndex * 4 + wordIndex] != cells[wordIndex]:
          matches = false
          break
      if matches:
        return slotIndex
      slotIndex = (slotIndex + 1) and (tableCapacity - 1)
    return slotIndex

  proc markVisited(cells: array[4, uint64]): bool =
    let slotIndex = findSlot(cells)
    if seenUsed[slotIndex]:
      return false
    seenUsed[slotIndex] = true
    for wordIndex in 0 .. 3:
      seenWords[slotIndex * 4 + wordIndex] = cells[wordIndex]
    usedCount += 1
    return true

  proc ensureCapacity() =
    if usedCount * 4 < tableCapacity * 3:
      return
    let oldCapacity = tableCapacity
    tableCapacity = tableCapacity shl 1
    var resizedWords = newSeq[uint64](tableCapacity * 4)
    var resizedUsed = newSeq[bool](tableCapacity)
    for oldSlot in 0 .. oldCapacity - 1:
      if seenUsed[oldSlot]:
        var hashValue = mixWord(seenWords[oldSlot * 4])
        for wordIndex in 1 .. 3:
          hashValue = hashValue xor mixWord(seenWords[oldSlot * 4 + wordIndex] + hashValue)
        var newSlot = int(hashValue and uint64(tableCapacity - 1))
        while resizedUsed[newSlot]:
          newSlot = (newSlot + 1) and (tableCapacity - 1)
        resizedUsed[newSlot] = true
        for wordIndex in 0 .. 3:
          resizedWords[newSlot * 4 + wordIndex] = seenWords[oldSlot * 4 + wordIndex]
    seenWords = resizedWords
    seenUsed = resizedUsed

  discard markVisited(startCells)
  var queueCells = newSeq[uint64](4 * 65536)
  var queuePositions = newSeq[int](65536)
  var queueDepths = newSeq[int](65536)
  var queueHead = 0
  var queueTail = 0
  for wordIndex in 0 .. 3:
    queueCells[queueTail * 4 + wordIndex] = startCells[wordIndex]
  queuePositions[queueTail] = startPosition
  queueDepths[queueTail] = 0
  queueTail += 1
  var answerSteps = -1
  while queueHead < queueTail and answerSteps == -1:
    var currentCells: array[4, uint64]
    for wordIndex in 0 .. 3:
      currentCells[wordIndex] = queueCells[queueHead * 4 + wordIndex]
    let currentPosition = queuePositions[queueHead]
    let currentDepth = queueDepths[queueHead]
    queueHead += 1
    if underlyingCode(cellCode(currentCells, currentPosition)) == exitCell:
      answerSteps = currentDepth
      break
    let currentRow = currentPosition div boardSize
    let currentColumn = currentPosition mod boardSize
    for directionIndex in 0 .. 3:
      let neighborRow = currentRow + directionRows[directionIndex]
      let neighborColumn = currentColumn + directionColumns[directionIndex]
      if neighborRow < 0 or neighborRow >= boardSize:
        continue
      if neighborColumn < 0 or neighborColumn >= boardSize:
        continue
      let neighborIndex = neighborRow * boardSize + neighborColumn
      let neighborCode = cellCode(currentCells, neighborIndex)
      if neighborCode == emptyCell:
        continue
      let neighborBase = underlyingCode(neighborCode)
      var nextCells = currentCells
      setCellCode(nextCells, currentPosition,
        underlyingCode(cellCode(currentCells, currentPosition)))
      setCellCode(nextCells, neighborIndex, neighborBase + markerOffset)
      if neighborBase == exitCell:
        answerSteps = currentDepth + 1
        break
      ensureCapacity()
      if markVisited(nextCells):
        if queueTail >= queuePositions.len:
          queueCells.setLen(queueCells.len * 2)
          queuePositions.setLen(queuePositions.len * 2)
          queueDepths.setLen(queueDepths.len * 2)
        for wordIndex in 0 .. 3:
          queueCells[queueTail * 4 + wordIndex] = nextCells[wordIndex]
        queuePositions[queueTail] = neighborIndex
        queueDepths[queueTail] = currentDepth + 1
        queueTail += 1
    if answerSteps != -1:
      break
    let standingHeight = underlyingCode(cellCode(currentCells, currentPosition))
    if standingHeight < 2 or standingHeight > 4:
      continue
    for directionIndex in 0 .. 3:
      let stepRow = directionRows[directionIndex]
      let stepColumn = directionColumns[directionIndex]
      var clearPath = true
      for step in 1 .. standingHeight:
        let targetRow = currentRow + stepRow * step
        let targetColumn = currentColumn + stepColumn * step
        if targetRow < 0 or targetRow >= boardSize or targetColumn < 0 or targetColumn >= boardSize:
          clearPath = false
          break
        let targetIndex = targetRow * boardSize + targetColumn
        if cellCode(currentCells, targetIndex) != emptyCell:
          clearPath = false
          break
      if not clearPath:
        continue
      var nextCells = currentCells
      setCellCode(nextCells, currentPosition, emptyCell)
      let landingIndex = (currentRow + stepRow) * boardSize + currentColumn + stepColumn
      for step in 1 .. standingHeight:
        let targetIndex = (currentRow + stepRow * step) * boardSize + currentColumn + stepColumn * step
        setCellCode(nextCells, targetIndex, fallenCell)
      setCellCode(nextCells, landingIndex, fallenCell + markerOffset)
      ensureCapacity()
      if markVisited(nextCells):
        if queueTail >= queuePositions.len:
          queueCells.setLen(queueCells.len * 2)
          queuePositions.setLen(queuePositions.len * 2)
          queueDepths.setLen(queueDepths.len * 2)
        for wordIndex in 0 .. 3:
          queueCells[queueTail * 4 + wordIndex] = nextCells[wordIndex]
        queuePositions[queueTail] = landingIndex
        queueDepths[queueTail] = currentDepth + 1
        queueTail += 1
  if answerSteps == -1:
    appendOutput("Impossible.")
  else:
    appendOutput($answerSteps)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

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

proc nextGridRow(data: string, pos: var int, width: int): string =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  result = ""
  var taken = 0
  while taken < width and pos < data.len:
    result.add data[pos]
    pos += 1
    taken += 1

proc countBits(value: int): int =
  var remaining = value
  result = 0
  while remaining != 0:
    remaining = remaining and (remaining - 1)
    result += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
var blockedMasks = newSeq[int](rowCount)
var rowIndex = 0
while rowIndex < rowCount:
  let gridRow = nextGridRow(inputData, scanPos, columnCount)
  var columnIndex = 0
  while columnIndex < columnCount:
    if gridRow[columnIndex] == 'X':
      blockedMasks[rowIndex] = blockedMasks[rowIndex] or (1 shl columnIndex)
    columnIndex += 1
  rowIndex += 1

var tilingDominoMasks = newSeq[int]()
var tilingBarMasks = newSeq[int]()
var tilingStarts = newSeq[int]()
var subsetPreviousMasks = newSeq[int32]()
var subsetNextMasks = newSeq[int32]()
var subsetBlocks = newSeq[int8]()
var activeDominoes = newSeq[int]()

proc enumerateTilings(column: int, dominoMask: int, barMask: int, dominoCount: int, barCount: int) =
  if column == columnCount:
    tilingDominoMasks.add dominoMask
    tilingBarMasks.add barMask
    tilingStarts.add subsetPreviousMasks.len
    let subsetTotal = 1 shl dominoCount
    var subset = 0
    while subset < subsetTotal:
      var previousMask = 0
      var dominoPosition = 0
      while dominoPosition < dominoCount:
        if (subset and (1 shl dominoPosition)) != 0:
          previousMask = previousMask or activeDominoes[dominoPosition]
        dominoPosition += 1
      let nextMask = dominoMask and (not previousMask)
      let placedNow = dominoCount - countBits(subset) + barCount
      subsetPreviousMasks.add int32(previousMask)
      subsetNextMasks.add int32(nextMask)
      subsetBlocks.add int8(placedNow)
      subset += 1
    return
  enumerateTilings(column + 1, dominoMask, barMask, dominoCount, barCount)
  if column + 1 < columnCount:
    let squareMask = (1 shl column) or (1 shl (column + 1))
    activeDominoes.add squareMask
    enumerateTilings(column + 2, dominoMask or squareMask, barMask, dominoCount + 1, barCount)
    activeDominoes.setLen activeDominoes.len - 1
  if column + 4 <= columnCount:
    let firstBit = 1 shl column
    let secondBit = 1 shl (column + 1)
    let thirdBit = 1 shl (column + 2)
    let fourthBit = 1 shl (column + 3)
    enumerateTilings(column + 4, dominoMask, barMask or firstBit or secondBit or thirdBit or fourthBit, dominoCount, barCount + 1)

enumerateTilings(0, 0, 0, 0, 0)
let tilingCount = tilingDominoMasks.len
let maskLimit = 1 shl columnCount
var rowValues = newSeq[int16](maskLimit)
var nextValues = newSeq[int16](maskLimit)
var maskIndex = 0
while maskIndex < maskLimit:
  rowValues[maskIndex] = int16(-1)
  nextValues[maskIndex] = int16(-1)
  maskIndex += 1
rowValues[0] = 0
let lastRow = rowCount - 1
rowIndex = 0
while rowIndex < rowCount:
  let blockedHere = blockedMasks[rowIndex]
  var blockedNext = 0
  if rowIndex == lastRow:
    blockedNext = maskLimit - 1
  else:
    blockedNext = blockedMasks[rowIndex + 1]
  maskIndex = 0
  while maskIndex < maskLimit:
    nextValues[maskIndex] = int16(-1)
    maskIndex += 1
  var tilingIndex = 0
  while tilingIndex < tilingCount:
    if (tilingDominoMasks[tilingIndex] and blockedHere) != 0 or (tilingBarMasks[tilingIndex] and blockedHere) != 0:
      tilingIndex += 1
      continue
    let subsetStart = tilingStarts[tilingIndex]
    var subsetEnd = subsetPreviousMasks.len
    if tilingIndex + 1 < tilingCount:
      subsetEnd = tilingStarts[tilingIndex + 1]
    var subsetIndex = subsetStart
    while subsetIndex < subsetEnd:
      let nextMask = int(subsetNextMasks[subsetIndex])
      if (nextMask and blockedNext) == 0:
        let previousMask = int(subsetPreviousMasks[subsetIndex])
        let previousBest = int(rowValues[previousMask])
        if previousBest >= 0:
          let candidate = previousBest + int(subsetBlocks[subsetIndex])
          if candidate > int(nextValues[nextMask]):
            nextValues[nextMask] = int16(candidate)
      subsetIndex += 1
    tilingIndex += 1
  swap rowValues, nextValues
  rowIndex += 1
appendOutput($int(rowValues[0]))
appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0

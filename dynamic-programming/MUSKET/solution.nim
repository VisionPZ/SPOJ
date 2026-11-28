const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const bitsPerWord = 64

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

proc addBit(lowWord: var uint64, highWord: var uint64, bitIndex: int) =
  if bitIndex < bitsPerWord:
    lowWord = lowWord or (1'u64 shl bitIndex)
  else:
    highWord = highWord or (1'u64 shl (bitIndex - bitsPerWord))

proc readRow(data: string, position: var int, beatsLow: var seq[uint64],
             beatsHigh: var seq[uint64], rowIndex: int, playerCount: int) =
  while position < data.len and (data[position] < '0' or data[position] > '1'):
    position += 1
  for j in 0..<playerCount:
    if data[position] == '1':
      addBit(beatsLow[rowIndex], beatsHigh[rowIndex], j)
    position += 1

proc hasBit(lowWord: uint64, highWord: uint64, bitIndex: int): bool =
  if bitIndex < bitsPerWord:
    return (lowWord and (1'u64 shl bitIndex)) != 0'u64
  return (highWord and (1'u64 shl (bitIndex - bitsPerWord))) != 0'u64

proc countBits(lowWord: uint64, highWord: uint64): int =
  var value = lowWord
  while value != 0'u64:
    value = value and (value - 1'u64)
    result += 1
  value = highWord
  while value != 0'u64:
    value = value and (value - 1'u64)
    result += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let playerCount = nextInt(inputData, scanPos)
  var beatsLow: seq[uint64]
  var beatsHigh: seq[uint64]
  beatsLow.setLen(playerCount)
  beatsHigh.setLen(playerCount)
  for i in 0..<playerCount:
    readRow(inputData, scanPos, beatsLow, beatsHigh, i, playerCount)
  let doubled = 2 * playerCount
  let cellCount = doubled * doubled
  var winLow: seq[uint64]
  var winHigh: seq[uint64]
  var hitLow: seq[uint64]
  var hitHigh: seq[uint64]
  winLow.setLen(cellCount)
  winHigh.setLen(cellCount)
  hitLow.setLen(cellCount)
  hitHigh.setLen(cellCount)
  for length in 1..playerCount:
    for leftIndex in 0..<doubled:
      let rightIndex = leftIndex + length - 1
      if rightIndex >= doubled:
        break
      let intervalIndex = leftIndex * doubled + rightIndex
      if length == 1:
        addBit(winLow[intervalIndex], winHigh[intervalIndex], leftIndex mod playerCount)
      else:
        for splitIndex in leftIndex..<rightIndex:
          let leftBase = leftIndex * doubled + splitIndex
          let rightBase = (splitIndex + 1) * doubled + rightIndex
          winLow[intervalIndex] = winLow[intervalIndex] or
            ((winLow[leftBase] and hitLow[rightBase]) or
             (winLow[rightBase] and hitLow[leftBase]))
          winHigh[intervalIndex] = winHigh[intervalIndex] or
            ((winHigh[leftBase] and hitHigh[rightBase]) or
             (winHigh[rightBase] and hitHigh[leftBase]))
      for player in 0..<playerCount:
        if (beatsLow[player] and winLow[intervalIndex]) != 0'u64 or
           (beatsHigh[player] and winHigh[intervalIndex]) != 0'u64:
          addBit(hitLow[intervalIndex], hitHigh[intervalIndex], player)
  var answerLow = 0'u64
  var answerHigh = 0'u64
  for startIndex in 0..<playerCount:
    let answerIndex = startIndex * doubled + startIndex + playerCount - 1
    answerLow = answerLow or winLow[answerIndex]
    answerHigh = answerHigh or winHigh[answerIndex]
  let winnerCount = countBits(answerLow, answerHigh)
  appendOutput($(winnerCount))
  outputBuffer.add '\n'
  for player in 0..<playerCount:
    if hasBit(answerLow, answerHigh, player):
      appendOutput($(player + 1))
      outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

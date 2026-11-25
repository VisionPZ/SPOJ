const flushBlockBytes = 1 shl 17
const boardSize = 5
const cellCount = boardSize * boardSize
const winningMark = 1
const losingMark = 2

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

var outcomeTable = newSeq[int8](1 shl cellCount)

proc positionWins(stones: int): bool =
  if stones == 0:
    return false
  let cached = outcomeTable[stones]
  if cached == winningMark:
    return true
  if cached == losingMark:
    return false
  for rowIndex in 0 .. boardSize - 1:
    var lineIndex = 0
    while lineIndex < boardSize:
      let cellBit = 1 shl (rowIndex * boardSize + lineIndex)
      if (stones and cellBit) == 0:
        lineIndex += 1
      else:
        let runStart = lineIndex
        while lineIndex < boardSize and (stones and (1 shl (rowIndex * boardSize + lineIndex))) != 0:
          lineIndex += 1
        var segmentStart = runStart
        while segmentStart < lineIndex:
          var removedMask = 0
          var segmentEnd = segmentStart
          while segmentEnd < lineIndex:
            removedMask = removedMask or (1 shl (rowIndex * boardSize + segmentEnd))
            let remaining = stones xor removedMask
            if remaining != 0 and not positionWins(remaining):
              outcomeTable[stones] = winningMark
              return true
            segmentEnd += 1
          segmentStart += 1
  for columnIndex in 0 .. boardSize - 1:
    var lineIndex = 0
    while lineIndex < boardSize:
      let cellBit = 1 shl (lineIndex * boardSize + columnIndex)
      if (stones and cellBit) == 0:
        lineIndex += 1
      else:
        let runStart = lineIndex
        while lineIndex < boardSize and (stones and (1 shl (lineIndex * boardSize + columnIndex))) != 0:
          lineIndex += 1
        var segmentStart = runStart
        while segmentStart < lineIndex:
          var removedMask = 0
          var segmentEnd = segmentStart
          while segmentEnd < lineIndex:
            removedMask = removedMask or (1 shl (segmentEnd * boardSize + columnIndex))
            let remaining = stones xor removedMask
            if remaining != 0 and not positionWins(remaining):
              outcomeTable[stones] = winningMark
              return true
            segmentEnd += 1
          segmentStart += 1
  outcomeTable[stones] = losingMark
  return false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  var stones = 0
  for cellIndex in 0 .. cellCount - 1:
    if nextInt(inputData, scanPos) == 1:
      stones = stones or (1 shl cellIndex)
  if positionWins(stones):
    appendOutput("winning")
  else:
    appendOutput("losing")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

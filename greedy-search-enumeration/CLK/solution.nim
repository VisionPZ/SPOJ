const flushBlockBytes = 1 shl 17
const columnCount = 10
const maximumHeight = 10
const hashBits = 20
const hashSize = 1 shl hashBits

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var stateCodes = newSeq[int64]()
var stateBuckets = newSeq[seq[int]](maximumHeight * columnCount + 1)
var hashKeys = newSeq[int64](hashSize)
var hashPositions = newSeq[int](hashSize)
var currentCode: int64 = 0

proc slotFor(code: int64): int =
  let mixed = code xor (code shr 19) xor (code shr 39)
  return int(mixed and int64(hashSize - 1))

proc insertState(code: int64, position: int) =
  var slot = slotFor(code)
  while hashKeys[slot] != -1:
    slot = (slot + 1) and (hashSize - 1)
  hashKeys[slot] = code
  hashPositions[slot] = position

proc findState(code: int64): int =
  var slot = slotFor(code)
  while true:
    if hashKeys[slot] == code:
      return hashPositions[slot]
    if hashKeys[slot] == -1:
      return -1
    slot = (slot + 1) and (hashSize - 1)

proc enumerateStates(column: int, ceiling: int, piecesSoFar: int) =
  if column == columnCount:
    let position = stateCodes.len
    stateCodes.add currentCode
    stateBuckets[piecesSoFar].add position
    insertState(currentCode, position)
    return
  var height = 0
  while height <= ceiling:
    let shift = 4 * column
    let fieldMask = int64(15) shl shift
    currentCode = (currentCode and not fieldMask) or (int64(height) shl shift)
    enumerateStates(column + 1, height, piecesSoFar + height)
    height += 1

for slot in 0 .. hashSize - 1:
  hashKeys[slot] = -1
enumerateStates(0, maximumHeight, 0)

var winFlags = newSeq[bool](stateCodes.len)
for pieces in 0 .. maximumHeight * columnCount:
  for position in stateBuckets[pieces]:
    let code = stateCodes[position]
    if code == 0:
      winFlags[position] = true
      continue
    var winning = false
    var chompColumn = 0
    while chompColumn < columnCount and not winning:
      let columnHeight = int((code shr (4 * chompColumn)) and int64(15))
      var chompRow = 0
      while chompRow < columnHeight:
        var successor = code
        var higherColumn = chompColumn
        while higherColumn < columnCount:
          let otherHeight = int((successor shr (4 * higherColumn)) and int64(15))
          if otherHeight > chompRow:
            successor = successor - (int64(otherHeight - chompRow) shl (4 * higherColumn))
          higherColumn += 1
        if not winFlags[findState(successor)]:
          winning = true
          break
        chompRow += 1
      chompColumn += 1
    winFlags[position] = winning

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  var positionCode: int64 = 0
  for column in 0 .. columnCount - 1:
    let columnHeight = nextInt(inputData, scanPos)
    positionCode = positionCode or (int64(columnHeight) shl (4 * column))
  if winFlags[findState(positionCode)]:
    appendOutput("W")
  else:
    appendOutput("L")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

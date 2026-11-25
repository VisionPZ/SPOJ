const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxWordChars = 200
const rowWordCount = 4
const bitsPerWord = 64

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextWordBounds(data: string, pos: var int): tuple[first, last: int] =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let first = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return (first, pos - 1)

proc setRowBit(rows: var seq[uint64], rowIndex, bitIndex: int) =
  let wordIndex = bitIndex shr 6
  let bitOffset = bitIndex and (bitsPerWord - 1)
  let cellIndex = rowIndex * rowWordCount + wordIndex
  rows[cellIndex] = rows[cellIndex] or (1'u64 shl bitOffset)

proc hasRowBit(rows: seq[uint64], rowIndex, bitIndex: int): bool =
  let wordIndex = bitIndex shr 6
  let bitOffset = bitIndex and (bitsPerWord - 1)
  let cellIndex = rowIndex * rowWordCount + wordIndex
  return ((rows[cellIndex] shr bitOffset) and 1'u64) == 1'u64

proc unionRows(rows: var seq[uint64], targetRow, sourceRow: int) =
  for wordIndex in 0 ..< rowWordCount:
    let targetIndex = targetRow * rowWordCount + wordIndex
    let sourceIndex = sourceRow * rowWordCount + wordIndex
    rows[targetIndex] = rows[targetIndex] or rows[sourceIndex]

proc isSetWord(data: string, first, last: int, rows: var seq[uint64]): bool =
  let wordLength = last - first + 1
  if wordLength < 2 or data[first] != '{' or data[last] != '}':
    return false
  if wordLength == 2:
    return true
  for cellIndex in 0 ..< (wordLength * rowWordCount):
    rows[cellIndex] = 0'u64
  for startOffset in countdown(wordLength - 1, 0):
    setRowBit(rows, startOffset, startOffset)
    if data[first + startOffset] == '{':
      for endOffset in startOffset + 1 ..< wordLength:
        if data[first + endOffset] == '}':
          if endOffset == startOffset + 1 or hasRowBit(rows, startOffset + 1, endOffset - 1):
            setRowBit(rows, startOffset, endOffset)
    for commaOffset in startOffset + 1 ..< wordLength - 1:
      if data[first + commaOffset] == ',' and hasRowBit(rows, startOffset, commaOffset - 1):
        unionRows(rows, startOffset, commaOffset + 1)
  return hasRowBit(rows, 1, wordLength - 2)

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var listRows = newSeq[uint64](maxWordChars * rowWordCount)
var outputBuffer = ""
for caseIndex in 1 .. caseCount:
  let wordBounds = nextWordBounds(inputData, scanPos)
  var verdict = "No Set"
  if isSetWord(inputData, wordBounds.first, wordBounds.last, listRows):
    verdict = "Set"
  outputBuffer.add "Word #"
  outputBuffer.add $caseIndex
  outputBuffer.add ": "
  outputBuffer.add verdict
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
outputBuffer.setLen 0

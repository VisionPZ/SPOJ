const flushBlockBytes = 1 shl 17
const wordBitCount = 64

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

proc collectSource(sourceBits: var seq[uint64], sourceRow: seq[uint64], baseIndex: int, wordCount: int) =
  for wordIndex in 0 .. wordCount - 1:
    sourceBits[wordIndex] = sourceBits[wordIndex] or sourceRow[baseIndex + wordIndex]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let colCount = nextInt(inputData, scanPos)
  let capacity = nextInt(inputData, scanPos)
  let wordCount = capacity div wordBitCount + 1
  let topValidBits = capacity mod wordBitCount + 1
  var capacityMask: uint64 = 0'u64
  if topValidBits == wordBitCount:
    capacityMask = not 0'u64
  else:
    capacityMask = (1'u64 shl topValidBits) - 1'u64
  var previousRow = newSeq[uint64](colCount * wordCount)
  var currentRow = newSeq[uint64](colCount * wordCount)
  var sourceBits = newSeq[uint64](wordCount)
  for rowIndex in 0 .. rowCount - 1:
    for colIndex in 0 .. colCount - 1:
      let shotValue = nextInt(inputData, scanPos)
      for wordIndex in 0 .. wordCount - 1:
        sourceBits[wordIndex] = 0'u64
      if rowIndex == 0 and colIndex == 0:
        sourceBits[0] = 1'u64
      else:
        if colIndex > 0:
          collectSource(sourceBits, currentRow, (colIndex - 1) * wordCount, wordCount)
        if rowIndex > 0:
          collectSource(sourceBits, previousRow, colIndex * wordCount, wordCount)
          if colIndex > 0:
            collectSource(sourceBits, previousRow, (colIndex - 1) * wordCount, wordCount)
      let destBase = colIndex * wordCount
      for wordIndex in 0 .. wordCount - 1:
        currentRow[destBase + wordIndex] = 0'u64
      let wordShift = shotValue div wordBitCount
      let bitShift = shotValue mod wordBitCount
      for wordIndex in 0 .. wordCount - 1:
        let sourceIndex = wordIndex - wordShift
        if sourceIndex >= 0:
          var shiftedBits = sourceBits[sourceIndex] shl bitShift
          if bitShift > 0 and sourceIndex > 0:
            shiftedBits = shiftedBits or (sourceBits[sourceIndex - 1] shr (wordBitCount - bitShift))
          currentRow[destBase + wordIndex] = shiftedBits
      let topWordIndex = destBase + wordCount - 1
      currentRow[topWordIndex] = currentRow[topWordIndex] and capacityMask
    swap previousRow, currentRow

  var bestShots = -1
  var wordIndex = wordCount - 1
  while wordIndex >= 0:
    let wordValue = previousRow[(colCount - 1) * wordCount + wordIndex]
    if wordValue != 0'u64:
      var bitIndex = wordBitCount - 1
      while bitIndex >= 0 and (wordValue and (1'u64 shl bitIndex)) == 0'u64:
        bitIndex -= 1
      bestShots = wordIndex * wordBitCount + bitIndex
      break
    wordIndex -= 1
  appendOutput($bestShots)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

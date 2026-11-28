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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let start = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[start ..< pos]

proc hasMoreNumbers(data: string, pos: int): bool =
  var index = pos
  while index < data.len:
    if data[index] >= '0' and data[index] <= '9':
      return true
    index += 1
  return false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc setBit(bits: var seq[uint64], position: int) =
  let wordIndex = position div 64
  bits[wordIndex] = bits[wordIndex] or (uint64(1) shl (position mod 64))

proc countBits(value: uint64): int =
  var current = value
  var total = 0
  while current != 0'u64:
    current = current and (current - 1'u64)
    total += 1
  return total

proc mergeTransition(currentBits: seq[uint64], matchBits: seq[uint64],
                     shiftAmount: int, target: var seq[uint64]) =
  let wordShift = shiftAmount div 64
  let bitShift = shiftAmount mod 64
  var carry: uint64 = 0
  for wordIndex in 0 .. target.len - 1:
    var value: uint64 = 0
    var nextCarry: uint64 = 0
    if wordIndex >= wordShift:
      let sourceIndex = wordIndex - wordShift
      let combined = currentBits[sourceIndex] and matchBits[sourceIndex]
      if bitShift == 0:
        value = combined
      else:
        value = (combined shl bitShift) or carry
        nextCarry = combined shr (64 - bitShift)
    target[wordIndex] = target[wordIndex] or value
    carry = nextCarry

while hasMoreNumbers(inputData, scanPos):
  let elementCount = nextInt(inputData, scanPos)
  let textLineCount = nextInt(inputData, scanPos)
  if elementCount == 0 and textLineCount == 0:
    break
  var elementStrings = newSeq[string](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    elementStrings[elementIndex] = nextToken(inputData, scanPos)
  var textData = ""
  for lineIndex in 0 .. textLineCount - 1:
    textData.add nextToken(inputData, scanPos)
  let textLength = textData.len
  let wordCount = textLength div 64 + 1
  var elementLengths = newSeq[int](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    elementLengths[elementIndex] = elementStrings[elementIndex].len

  var matchBits = newSeq[seq[uint64]](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    matchBits[elementIndex] = newSeq[uint64](wordCount)
    let elementLength = elementLengths[elementIndex]
    for startPosition in 0 .. textLength - elementLength:
      var matches = true
      for offset in 0 .. elementLength - 1:
        if textData[startPosition + offset] != elementStrings[elementIndex][offset]:
          matches = false
          break
      if matches:
        setBit(matchBits[elementIndex], startPosition)

  let maskCount = 1 shl elementCount
  let fullMask = maskCount - 1
  var endBits = newSeq[seq[uint64]](maskCount)
  for mask in 0 .. maskCount - 1:
    endBits[mask] = newSeq[uint64](wordCount)
  for position in 0 .. textLength:
    setBit(endBits[0], position)

  for mask in 0 .. maskCount - 1:
    for elementIndex in 0 .. elementCount - 1:
      if (mask and (1 shl elementIndex)) == 0:
        let nextMask = mask or (1 shl elementIndex)
        mergeTransition(endBits[mask], matchBits[elementIndex],
                        elementLengths[elementIndex], endBits[nextMask])

  var occurrenceCount = 0
  for word in endBits[fullMask]:
    occurrenceCount += countBits(word)
  appendOutput($(occurrenceCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

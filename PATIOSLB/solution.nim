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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc setBit(bits: var seq[uint64], position: int) =
  let wordIndex = position shr 6
  let bitOffset = position and 63
  bits[wordIndex] = bits[wordIndex] or (uint64(1) shl uint(bitOffset))

proc testBit(bits: seq[uint64], position: int): bool =
  let wordIndex = position shr 6
  let bitOffset = position and 63
  return (bits[wordIndex] and (uint64(1) shl uint(bitOffset))) != uint64(0)

proc shiftOrInto(destination: var seq[uint64], source: seq[uint64], shiftAmount: int) =
  let wordShift = shiftAmount shr 6
  let bitShift = shiftAmount and 63
  var sourceIndex = 0
  while sourceIndex < source.len:
    let sourceValue = source[sourceIndex]
    if sourceValue != uint64(0):
      let lowTarget = sourceIndex + wordShift
      if bitShift == 0:
        if lowTarget < destination.len:
          destination[lowTarget] = destination[lowTarget] or sourceValue
      else:
        if lowTarget < destination.len:
          destination[lowTarget] = destination[lowTarget] or (sourceValue shl uint(bitShift))
        let highTarget = lowTarget + 1
        if highTarget < destination.len:
          destination[highTarget] = destination[highTarget] or (sourceValue shr uint(64 - bitShift))
    sourceIndex += 1

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rowLength = nextInt(inputData, scanPos)
  let slabCount = nextInt(inputData, scanPos)
  var slabLengths = newSeq[int](slabCount)
  var slabCursor = 0
  while slabCursor < slabCount:
    slabLengths[slabCursor] = nextInt(inputData, scanPos)
    slabCursor += 1
  var sortCursor = 1
  while sortCursor < slabCount:
    let insertionValue = slabLengths[sortCursor]
    var shiftCursor = sortCursor - 1
    while shiftCursor >= 0 and slabLengths[shiftCursor] < insertionValue:
      slabLengths[shiftCursor + 1] = slabLengths[shiftCursor]
      shiftCursor -= 1
    slabLengths[shiftCursor + 1] = insertionValue
    sortCursor += 1
  let targetSum = rowLength - 1
  if targetSum < 0:
    appendOutput("-1\n")
    continue
  let wordCount = targetSum div 64 + 1
  var suffixBits = newSeq[seq[uint64]](slabCount + 1)
  var emptyBits = newSeq[uint64](wordCount)
  setBit(emptyBits, 0)
  suffixBits[slabCount] = emptyBits
  var reverseCursor = slabCount - 1
  while reverseCursor >= 0:
    suffixBits[reverseCursor] = suffixBits[reverseCursor + 1]
    shiftOrInto(suffixBits[reverseCursor], suffixBits[reverseCursor + 1], slabLengths[reverseCursor] + 1)
    reverseCursor -= 1
  var remainingSum = targetSum
  var chosenLengths = newSeq[int](0)
  var itemCursor = 0
  while itemCursor < slabCount:
    let slabWeight = slabLengths[itemCursor] + 1
    if slabWeight <= remainingSum and testBit(suffixBits[itemCursor + 1], remainingSum - slabWeight):
      chosenLengths.add slabLengths[itemCursor]
      remainingSum = remainingSum - slabWeight
    itemCursor += 1
  if remainingSum != 0:
    appendOutput("-1\n")
  else:
    var chosenCursor = 0
    while chosenCursor < chosenLengths.len:
      if chosenCursor > 0:
        appendOutput(" ")
      appendOutput($chosenLengths[chosenCursor])
      chosenCursor += 1
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0

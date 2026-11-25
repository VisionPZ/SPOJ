const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const bitsPerWord = 64

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value

proc maxFieldSum(capacity: int, fieldSizes: seq[int]): int =
  let wordCount = capacity div bitsPerWord + 1
  var reachable = newSeq[uint64](wordCount)
  reachable[0] = 1'u64
  for fieldSize in fieldSizes:
    if fieldSize > capacity: continue
    let wordShift = fieldSize div bitsPerWord
    let bitShift = fieldSize mod bitsPerWord
    for wordIndex in countdown(wordCount - 1, wordShift):
      var shifted = reachable[wordIndex - wordShift] shl bitShift
      if bitShift > 0 and wordIndex - wordShift - 1 >= 0:
        shifted = shifted or (reachable[wordIndex - wordShift - 1] shr (bitsPerWord - bitShift))
      reachable[wordIndex] = reachable[wordIndex] or shifted
  for total in countdown(capacity, 0):
    if (reachable[total div bitsPerWord] and (1'u64 shl (total mod bitsPerWord))) != 0'u64:
      return total
  return 0

proc descendingSort(values: var seq[int]) =
  if values.len > 1:
    for rightIndex in 1 ..< values.len:
      let keyValue = values[rightIndex]
      var leftIndex = rightIndex - 1
      while leftIndex >= 0 and values[leftIndex] < keyValue:
        values[leftIndex + 1] = values[leftIndex]
        leftIndex -= 1
      values[leftIndex + 1] = keyValue

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

for _ in 0 ..< caseCount:
  let treeTarget = nextInt(inputData, scanPos)
  let fieldCount = nextInt(inputData, scanPos)
  let stripCount = nextInt(inputData, scanPos)
  var fieldSizes = newSeq[int](fieldCount)
  var fieldTotal = 0
  for fieldIndex in 0 ..< fieldCount:
    fieldSizes[fieldIndex] = nextInt(inputData, scanPos)
    fieldTotal += fieldSizes[fieldIndex]
  var stripSizes = newSeq[int](stripCount)
  for stripIndex in 0 ..< stripCount:
    stripSizes[stripIndex] = nextInt(inputData, scanPos)
  let bestFieldSum = maxFieldSum(treeTarget, fieldSizes)
  var answer = 0
  if bestFieldSum == treeTarget:
    answer = treeTarget
  elif bestFieldSum < fieldTotal:
    answer = treeTarget - 1
  else:
    descendingSort(stripSizes)
    var covered = 0
    var usedStrips = 0
    for stripSize in stripSizes:
      covered += stripSize
      usedStrips += 1
      if covered >= treeTarget - bestFieldSum: break
    answer = treeTarget - usedStrips
  outputBuffer.add $answer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0

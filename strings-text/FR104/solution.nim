const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const hexDigits = "0123456789ABCDEF"

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextLineBounds(data: string, pos: var int): tuple[first, last: int] =
  var lineStart = pos
  while lineStart < data.len and (data[lineStart] == '\n' or data[lineStart] == '\r'):
    inc lineStart
  var lineEnd = lineStart
  while lineEnd < data.len and data[lineEnd] != '\n' and data[lineEnd] != '\r':
    inc lineEnd
  pos = lineEnd
  while pos < data.len and (data[pos] == '\n' or data[pos] == '\r'):
    inc pos
  result = (lineStart, lineEnd)

proc nameOrder(left: string, right: string): int =
  let sharedLength = if left.len < right.len: left.len else: right.len
  for idx in 0..<sharedLength:
    var leftCode = int(left[idx])
    var rightCode = int(right[idx])
    if leftCode >= 65 and leftCode <= 90:
      leftCode += 32
    if rightCode >= 65 and rightCode <= 90:
      rightCode += 32
    if leftCode < rightCode:
      return -1
    if leftCode > rightCode:
      return 1
  if left.len < right.len:
    return -1
  if left.len > right.len:
    return 1
  for idx in 0..<left.len:
    if int(left[idx]) < int(right[idx]):
      return -1
    if int(left[idx]) > int(right[idx]):
      return 1
  return 0

proc partitionNames(names: var seq[string], low: int, high: int): int =
  let middle = (low + high) div 2
  let heldMiddle = names[middle]
  names[middle] = names[high]
  names[high] = heldMiddle
  let pivot = names[high]
  var store = low
  for idx in low..<high:
    if nameOrder(names[idx], pivot) < 0:
      let heldName = names[store]
      names[store] = names[idx]
      names[idx] = heldName
      inc store
  let heldLast = names[store]
  names[store] = names[high]
  names[high] = heldLast
  return store

proc sortNames(names: var seq[string], low: int, high: int) =
  if low >= high:
    return
  let pivotPos = partitionNames(names, low, high)
  sortNames(names, low, pivotPos - 1)
  sortNames(names, pivotPos + 1, high)

var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()

var nameList: seq[string] = @[]
var encryptionKey = -1

while scanPos < inputData.len:
  let lineBounds = nextLineBounds(inputData, scanPos)
  let lineStart = lineBounds.first
  let lineEnd = lineBounds.last
  var firstByte = lineStart
  while firstByte < lineEnd and inputData[firstByte] <= ' ':
    inc firstByte
  var lastByte = lineEnd
  while lastByte > firstByte and inputData[lastByte - 1] <= ' ':
    dec lastByte
  if firstByte >= lastByte:
    continue
  if encryptionKey < 0:
    var keyValue = 0
    for position in firstByte..<lastByte:
      if inputData[position] >= '0' and inputData[position] <= '9':
        keyValue = keyValue * 10 + int(inputData[position]) - firstDigitValue
    if keyValue > 3:
      break
    encryptionKey = keyValue
  else:
    if lastByte - firstByte == 1 and inputData[firstByte] == '*':
      break
    nameList.add inputData[firstByte .. lastByte - 1]

if nameList.len > 0:
  sortNames(nameList, 0, nameList.len - 1)
for name in nameList:
  for idx in 0..<name.len:
    let codeValue = int(name[idx]) + encryptionKey
    outputBuffer.add hexDigits[codeValue div 16]
    outputBuffer.add hexDigits[codeValue mod 16]
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0

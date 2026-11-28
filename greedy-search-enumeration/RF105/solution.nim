const flushBlockBytes = 1 shl 17

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

proc textOrder(left: string, right: string): int =
  let sharedLength = if left.len < right.len: left.len else: right.len
  for idx in 0..<sharedLength:
    if int(left[idx]) < int(right[idx]):
      return -1
    if int(left[idx]) > int(right[idx]):
      return 1
  if left.len < right.len:
    return -1
  if left.len > right.len:
    return 1
  return 0

proc partitionText(names: var seq[string], low: int, high: int): int =
  let middle = (low + high) div 2
  let heldMiddle = names[middle]
  names[middle] = names[high]
  names[high] = heldMiddle
  let pivot = names[high]
  var store = low
  for idx in low..<high:
    if textOrder(names[idx], pivot) < 0:
      let heldName = names[store]
      names[store] = names[idx]
      names[idx] = heldName
      inc store
  let heldLast = names[store]
  names[store] = names[high]
  names[high] = heldLast
  return store

proc sortText(names: var seq[string], low: int, high: int) =
  if low >= high:
    return
  let pivotPos = partitionText(names, low, high)
  sortText(names, low, pivotPos - 1)
  sortText(names, pivotPos + 1, high)

proc readNames(data: string, lineStart: int, lineEnd: int,
               names: var seq[string]) =
  var cursor = lineStart
  while cursor < lineEnd and (data[cursor] < '0' or data[cursor] > '9'):
    inc cursor
  while cursor < lineEnd and data[cursor] >= '0' and data[cursor] <= '9':
    inc cursor
  while cursor < lineEnd:
    while cursor < lineEnd and data[cursor] <= ' ':
      inc cursor
    if cursor >= lineEnd:
      break
    let tokenStart = cursor
    while cursor < lineEnd and data[cursor] > ' ':
      inc cursor
    names.add data[tokenStart .. cursor - 1]

var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()

var cakeNames: seq[string] = @[]
var creamNames: seq[string] = @[]
var rowsSeen = 0

while scanPos < inputData.len and rowsSeen < 2:
  let lineBounds = nextLineBounds(inputData, scanPos)
  let lineStart = lineBounds.first
  let lineEnd = lineBounds.last
  var hasContent = false
  for position in lineStart..<lineEnd:
    if inputData[position] > ' ':
      hasContent = true
      break
  if not hasContent:
    continue
  if rowsSeen == 0:
    readNames(inputData, lineStart, lineEnd, cakeNames)
  else:
    readNames(inputData, lineStart, lineEnd, creamNames)
  inc rowsSeen

if cakeNames.len > 0:
  sortText(cakeNames, 0, cakeNames.len - 1)
if creamNames.len > 0:
  sortText(creamNames, 0, creamNames.len - 1)

var printedName = false
proc printUniqueName(name: string) =
  if printedName:
    outputBuffer.add ' '
  outputBuffer.add name
  printedName = true

var cakeIndex = 0
var creamIndex = 0
while cakeIndex < cakeNames.len or creamIndex < creamNames.len:
  if creamIndex >= creamNames.len or (cakeIndex < cakeNames.len and
      textOrder(cakeNames[cakeIndex], creamNames[creamIndex]) < 0):
    printUniqueName(cakeNames[cakeIndex])
    inc cakeIndex
    while cakeIndex < cakeNames.len and
        textOrder(cakeNames[cakeIndex - 1], cakeNames[cakeIndex]) == 0:
      inc cakeIndex
  elif cakeIndex >= cakeNames.len or
      textOrder(cakeNames[cakeIndex], creamNames[creamIndex]) > 0:
    printUniqueName(creamNames[creamIndex])
    inc creamIndex
    while creamIndex < creamNames.len and
        textOrder(creamNames[creamIndex - 1], creamNames[creamIndex]) == 0:
      inc creamIndex
  else:
    inc cakeIndex
    while cakeIndex < cakeNames.len and
        textOrder(cakeNames[cakeIndex - 1], cakeNames[cakeIndex]) == 0:
      inc cakeIndex
    inc creamIndex
    while creamIndex < creamNames.len and
        textOrder(creamNames[creamIndex - 1], creamNames[creamIndex]) == 0:
      inc creamIndex
appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0

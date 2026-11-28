const flushBlockBytes = 1 shl 17
const termsToAppend = 3

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc hasNextNumber(data: string, pos: int): bool =
  var checkPos = pos
  while checkPos < data.len and (data[checkPos] < '0' or data[checkPos] > '9'):
    checkPos += 1
  return checkPos < data.len

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var sequence = newSeq[int64]()
while hasNextNumber(inputData, scanPos):
  sequence.add int64(nextInt(inputData, scanPos))
if sequence.len == 0:
  sequence.add 0

var differenceRows = newSeq[seq[int64]]()
differenceRows.add sequence
while true:
  let previousRow = differenceRows[differenceRows.len - 1]
  if previousRow.len <= 1:
    break
  var nextRow = newSeq[int64](previousRow.len - 1)
  for index in 0 .. previousRow.len - 2:
    nextRow[index] = previousRow[index + 1] - previousRow[index]
  differenceRows.add nextRow
  var allZero = true
  for value in nextRow:
    if value != 0:
      allZero = false
      break
  if allZero:
    break

let bottomIndex = differenceRows.len - 1
let bottomRow = differenceRows[bottomIndex]
var bottomFill: int64 = 0
if bottomRow.len == 1:
  bottomFill = bottomRow[0]
for step in 0 .. termsToAppend - 1:
  differenceRows[bottomIndex].add bottomFill
  var upperIndex = bottomIndex - 1
  while upperIndex >= 0:
    let upperLast = differenceRows[upperIndex][differenceRows[upperIndex].len - 1]
    let lowerLast = differenceRows[upperIndex + 1][differenceRows[upperIndex + 1].len - 1]
    differenceRows[upperIndex].add upperLast + lowerLast
    upperIndex -= 1

let resultRow = differenceRows[0]
let firstNextIndex = resultRow.len - termsToAppend
for step in 0 .. termsToAppend - 1:
  if step > 0:
    appendOutput(" ")
  appendOutput($resultRow[firstNextIndex + step])
appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0

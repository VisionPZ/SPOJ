import algorithm

const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc buildVector(size: int): seq[int64] =
  result = newSeq[int64](size)
  for index in 0..<size:
    let position = index + 1
    if (position and 1) == 0:
      result[index] = int64(position) * int64(position) + 1'i64
    else:
      result[index] = 3'i64 * int64(position + 1)

proc sortDescending(values: seq[int64]): seq[int64] =
  result = values
  result.sort(proc(left, right: int64): int =
    if left > right: -1
    elif left < right: 1
    else: 0)

proc sortAscending(values: seq[int64]): seq[int64] =
  result = values
  result.sort(proc(left, right: int64): int =
    if left < right: -1
    elif left > right: 1
    else: 0)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc writeVector(values: seq[int64]) =
  for index in 0..<values.len:
    if index > 0:
      outputBuffer.add ' '
    appendOutput($(values[index]))
  outputBuffer.add '\n'

let vectorSize = nextInt(inputData, scanPos)
let originalVector = buildVector(vectorSize)
var evenValues: seq[int64] = @[]
var oddValues: seq[int64] = @[]
for value in originalVector:
  if (value and 1'i64) == 0'i64:
    evenValues.add value
  else:
    oddValues.add value

appendOutput("SIN ORDENAR")
outputBuffer.add '\n'
writeVector(originalVector)
appendOutput("ORDENADO")
outputBuffer.add '\n'
writeVector(sortDescending(evenValues) & sortAscending(oddValues))

stdout.write outputBuffer
outputBuffer.setLen 0

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt(data: string, position: var int): int64 =
  while position < data.len and data[position] != '-' and (data[position] < '0' or data[position] > '9'):
    position += 1
  var negative = false
  if position < data.len and data[position] == '-':
    negative = true
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc radixSortAscending(values: var seq[int64], count: var seq[int], scratch: var seq[int64]) =
  let n = values.len
  var minValue = values[0]
  var maxValue = values[0]
  for i in 1..<n:
    if values[i] < minValue: minValue = values[i]
    if values[i] > maxValue: maxValue = values[i]
  if minValue == maxValue: return
  for i in 0..<n: values[i] = values[i] - minValue
  var walk = cast[uint64](maxValue - minValue)
  var bits = 0
  while walk > 0'u64:
    bits += 1
    walk = walk shr 1
  let passes = (bits + 11) div 12
  let digitMask = 0xFFF'u64
  scratch.setLen n
  var shift = 0
  for pass in 0..<passes:
    for i in 0..4095: count[i] = 0
    for i in 0..<n:
      inc count[int((cast[uint64](values[i]) shr shift) and digitMask)]
    var total = 0
    for i in 0..4095:
      let c = count[i]
      count[i] = total
      total += c
    for i in 0..<n:
      let d = int((cast[uint64](values[i]) shr shift) and digitMask)
      scratch[count[d]] = values[i]
      inc count[d]
    swap(values, scratch)
    shift += 12

let caseCount = int(nextSignedInt(inputData, scanPos))
var values = newSeq[int64](0)
var scratchValues = newSeq[int64](0)
var count = newSeq[int](4096)
for caseIndex in 0..<caseCount:
  let elementCount = int(nextSignedInt(inputData, scanPos))
  values.setLen elementCount
  for i in 0..<elementCount:
    values[i] = nextSignedInt(inputData, scanPos)
  radixSortAscending(values, count, scratchValues)
  var closestGap = values[1] - values[0]
  for i in 1..<elementCount:
    let gap = values[i] - values[i - 1]
    if gap < closestGap:
      closestGap = gap
      if closestGap == 0: break
  appendOutput($closestGap & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0

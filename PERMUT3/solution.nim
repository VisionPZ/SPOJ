const flushBlockBytes = 1 shl 17
const limbBase = 1000000000
const limbDigits = 9

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

proc addBig(target: var seq[int], source: seq[int]) =
  var carry = 0
  var limbIndex = 0
  while limbIndex < source.len:
    if limbIndex >= target.len:
      target.add 0
    let total = target[limbIndex] + source[limbIndex] + carry
    target[limbIndex] = total mod limbBase
    carry = total div limbBase
    limbIndex += 1
  while carry > 0:
    if limbIndex >= target.len:
      target.add 0
    let total = target[limbIndex] + carry
    target[limbIndex] = total mod limbBase
    carry = total div limbBase
    limbIndex += 1

proc bigToString(value: seq[int]): string =
  if value.len == 0:
    return "0"
  var text = $value[value.len - 1]
  var limbIndex = value.len - 2
  while limbIndex >= 0:
    var piece = $value[limbIndex]
    while piece.len < limbDigits:
      piece = "0" & piece
    text.add piece
    limbIndex -= 1
  return text

while true:
  let count = nextInt(inputData, scanPos)
  if count == 0:
    break
  var pattern = newSeq[int](count)
  if count >= 1:
    var previousValue = nextInt(inputData, scanPos)
    for position in 1 .. count - 1:
      let currentValue = nextInt(inputData, scanPos)
      if currentValue > previousValue:
        pattern[position - 1] = 1
      previousValue = currentValue
  var previousRow = newSeq[seq[int]](count + 1)
  previousRow[1] = @[1]
  var step = 1
  while step < count:
    var prefixSums = newSeq[seq[int]](step + 1)
    var suffixSums = newSeq[seq[int]](step + 2)
    for rank in 1 .. step:
      prefixSums[rank] = prefixSums[rank - 1]
      addBig(prefixSums[rank], previousRow[rank])
    for rank in countdown(step, 1):
      suffixSums[rank] = suffixSums[rank + 1]
      addBig(suffixSums[rank], previousRow[rank])
    var currentRow = newSeq[seq[int]](step + 2)
    for rank in 1 .. step + 1:
      if pattern[step - 1] == 1:
        currentRow[rank] = prefixSums[rank - 1]
      else:
        currentRow[rank] = suffixSums[rank]
    previousRow = currentRow
    step += 1
  var answer: seq[int]
  for rank in 1 .. count:
    addBig(answer, previousRow[rank])
  appendOutput(bigToString(answer))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

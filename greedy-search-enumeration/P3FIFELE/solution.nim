const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int, value: var int64): bool =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  if pos >= data.len:
    return false
  var negative = false
  if data[pos] == '-':
    negative = true
    pos += 1
    if pos >= data.len or data[pos] < '0' or data[pos] > '9':
      return false
  value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  if negative:
    value = -value
  return true

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc squareDigits(value: int64): string =
  var magnitude = value
  if magnitude < 0:
    magnitude = -magnitude
  var digits = newSeq[int]()
  while magnitude > 0:
    digits.add(int(magnitude mod 10))
    magnitude = magnitude div 10
  if digits.len == 0:
    digits.add 0
  var product = newSeq[int](digits.len * 2 + 1)
  for leftIndex in 0 .. digits.len - 1:
    for rightIndex in 0 .. digits.len - 1:
      product[leftIndex + rightIndex] += digits[leftIndex] * digits[rightIndex]
  for carryIndex in 0 .. product.len - 2:
    product[carryIndex + 1] += product[carryIndex] div 10
    product[carryIndex] = product[carryIndex] mod 10
  var topIndex = product.len - 1
  while topIndex > 0 and product[topIndex] == 0:
    topIndex -= 1
  var digitText = ""
  var digitIndex = topIndex
  while digitIndex >= 0:
    digitText.add char(ord('0') + product[digitIndex])
    digitIndex -= 1
  return digitText

var foundCount = 0
var fifthValue: int64 = 0
var currentValue: int64 = 0
while nextInt(inputData, scanPos, currentValue):
  foundCount += 1
  if foundCount == 5:
    fifthValue = currentValue
    break
if foundCount >= 5:
  appendOutput(squareDigits(fifthValue))
else:
  appendOutput("0")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

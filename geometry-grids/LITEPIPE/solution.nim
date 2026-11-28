const
  readChunkBytes = 1 shl 16
  flushBlockBytes = 1 shl 18
  firstDigitValue = 48
  maxBentPoints = 200
  searchIterations = 60

var inputData = newString(readChunkBytes)
var bytesRead = 0
while true:
  if bytesRead + readChunkBytes > inputData.len:
    inputData.setLen(inputData.len * 2)
  let chunkSize = stdin.readBuffer(addr inputData[bytesRead], readChunkBytes)
  if chunkSize == 0:
    break
  bytesRead += chunkSize
inputData.setLen(bytesRead)

var i = 0

proc skipWhite(data: string, i: var int) =
  while i < data.len and (data[i] == ' ' or data[i] == '\n' or
      data[i] == '\r' or data[i] == '\t'):
    i += 1

proc nextInt(data: string, i: var int): int =
  skipWhite(data, i)
  var negative = false
  if i < data.len and data[i] == '-':
    negative = true
    i += 1
  elif i < data.len and data[i] == '+':
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + (ord(data[i]) - firstDigitValue)
    i += 1
  if negative:
    value = -value
  result = value

proc nextReal(data: string, i: var int): float =
  skipWhite(data, i)
  var sign = 1.0
  if i < data.len and data[i] == '-':
    sign = -1.0
    i += 1
  elif i < data.len and data[i] == '+':
    i += 1
  var whole = 0.0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    whole = whole * 10.0 + float(ord(data[i]) - firstDigitValue)
    i += 1
  var fraction = 0.0
  var scale = 1.0
  if i < data.len and data[i] == '.':
    i += 1
    while i < data.len and data[i] >= '0' and data[i] <= '9':
      scale = scale * 10.0
      fraction += float(ord(data[i]) - firstDigitValue) / scale
      i += 1
  var exponent = 0
  if i < data.len and (data[i] == 'e' or data[i] == 'E'):
    i += 1
    var exponentSign = 1
    if i < data.len and data[i] == '-':
      exponentSign = -1
      i += 1
    elif i < data.len and data[i] == '+':
      i += 1
    var exponentValue = 0
    while i < data.len and data[i] >= '0' and data[i] <= '9':
      exponentValue = exponentValue * 10 + (ord(data[i]) - firstDigitValue)
      i += 1
    exponent = exponentSign * exponentValue
  var magnitude = whole + fraction
  if exponent > 0:
    var step = 0
    while step < exponent:
      magnitude *= 10.0
      step += 1
  elif exponent < 0:
    var step = 0
    while step > exponent:
      magnitude /= 10.0
      step -= 1
  result = sign * magnitude

var upperX = newSeq[float](maxBentPoints + 2)
var upperY = newSeq[float](maxBentPoints + 2)
var pointX = newSeq[float](maxBentPoints + 2)
var pointY = newSeq[float](maxBentPoints + 2)

proc feasibleAt(limitX: float, count: int): bool =
  var pointCount = 0
  for k in 0 .. count - 1:
    if upperX[k] > limitX:
      break
    pointX[pointCount] = upperX[k]
    pointY[pointCount] = upperY[k]
    pointCount += 1
  if pointCount < count and pointCount > 0:
    let i = pointCount - 1
    let j = pointCount
    let span = upperX[j] - upperX[i]
    let weight = (limitX - upperX[i]) / span
    pointX[pointCount] = limitX
    pointY[pointCount] = upperY[i] +
        weight * (upperY[j] - upperY[i])
    pointCount += 1
  var slopeLow = -1e100
  var slopeHigh = 1e100
  for i in 0 .. pointCount - 2:
    for j in i + 1 .. pointCount - 1:
      let dx = pointX[j] - pointX[i]
      if dx <= 0.0:
        continue
      let center = (pointY[j] - pointY[i]) / dx
      let halfWidth = 1.0 / dx
      let candidateLow = center - halfWidth
      let candidateHigh = center + halfWidth
      if candidateLow > slopeLow:
        slopeLow = candidateLow
      if candidateHigh < slopeHigh:
        slopeHigh = candidateHigh
      if slopeLow > slopeHigh:
        return false
  result = true

proc furthestReach(count: int): float =
  var low = upperX[0]
  var high = upperX[count - 1]
  var iteration = 0
  while iteration < searchIterations:
    let middle = (low + high) * 0.5
    if feasibleAt(middle, count):
      low = middle
    else:
      high = middle
    iteration += 1
  result = low

var outputBuffer = ""

proc appendFixedTwo(buf: var string, value: float) =
  var adjusted = value
  if adjusted < 0.0 and adjusted > -0.005:
    adjusted = 0.0
  var scaled = adjusted * 100.0
  var rounded: int64
  if scaled >= 0.0:
    rounded = int64(scaled + 0.5)
  else:
    rounded = -int64(-scaled + 0.5)
  if rounded == 0:
    buf.add "0.00\n"
    return
  var negative = false
  if rounded < 0:
    negative = true
    rounded = -rounded
  var digitStore: array[24, char]
  var digitCount = 0
  var quotient = rounded
  while quotient > 0:
    digitStore[digitCount] = char(firstDigitValue + int(quotient mod 10))
    digitCount += 1
    quotient = quotient div 10
  while digitCount < 2:
    digitStore[digitCount] = '0'
    digitCount += 1
  if negative:
    buf.add '-'
  if digitCount == 2:
    buf.add '0'
  var i = digitCount - 1
  while i >= 2:
    buf.add digitStore[i]
    i -= 1
  buf.add '.'
  buf.add digitStore[1]
  buf.add digitStore[0]
  buf.add '\n'

while i < inputData.len:
  let count = nextInt(inputData, i)
  if count == 0:
    break
  for k in 0 .. count - 1:
    upperX[k] = nextReal(inputData, i)
    upperY[k] = nextReal(inputData, i)
  let answer = furthestReach(count)
  appendFixedTwo(outputBuffer, answer)
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0

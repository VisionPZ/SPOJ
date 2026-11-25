import math

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const digitBase = 1000
const digitGroup = 3
const piValue = 3.14159265358979323846

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc skipSpaces(data: string, pos: var int) =
  while pos < data.len and data[pos] <= ' ':
    pos += 1

proc readCount(data: string, pos: var int): int =
  skipSpaces(data, pos)
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc readToken(data: string, pos: var int, start: var int, finish: var int) =
  skipSpaces(data, pos)
  start = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  finish = pos

proc toChunks(data: string, start: int, finish: int): seq[int] =
  result = @[]
  var right = finish - 1
  while right >= start:
    var chunk = 0
    var place = 1
    var digitIdx = 0
    while right >= start and digitIdx < digitGroup:
      chunk += (int(data[right]) - firstDigitValue) * place
      place *= 10
      right -= 1
      digitIdx += 1
    result.add chunk
  while result.len > 1 and result[result.len - 1] == 0:
    result.setLen(result.len - 1)

proc fft(realPart: var seq[float], imagPart: var seq[float], invert: bool) =
  let size = realPart.len
  var revIdx = 0
  for idx in 1 .. size - 1:
    var bit = size div 2
    while (revIdx and bit) != 0:
      revIdx = revIdx xor bit
      bit = bit div 2
    revIdx = revIdx xor bit
    if idx < revIdx:
      swap realPart[idx], realPart[revIdx]
      swap imagPart[idx], imagPart[revIdx]
  var blockLen = 2
  while blockLen <= size:
    let angle = (if invert: 2.0 else: -2.0) * piValue / float(blockLen)
    let stepRe = cos(angle)
    let stepIm = sin(angle)
    var blockStart = 0
    while blockStart < size:
      var twiddleRe = 1.0
      var twiddleIm = 0.0
      let half = blockLen div 2
      var offset = 0
      while offset < half:
        let leftRe = realPart[blockStart + offset]
        let leftIm = imagPart[blockStart + offset]
        let rightRe = realPart[blockStart + offset + half] * twiddleRe - imagPart[blockStart + offset + half] * twiddleIm
        let rightIm = realPart[blockStart + offset + half] * twiddleIm + imagPart[blockStart + offset + half] * twiddleRe
        realPart[blockStart + offset] = leftRe + rightRe
        imagPart[blockStart + offset] = leftIm + rightIm
        realPart[blockStart + offset + half] = leftRe - rightRe
        imagPart[blockStart + offset + half] = leftIm - rightIm
        let nextRe = twiddleRe * stepRe - twiddleIm * stepIm
        twiddleIm = twiddleRe * stepIm + twiddleIm * stepRe
        twiddleRe = nextRe
        offset += 1
      blockStart += blockLen
    blockLen *= 2
  if invert:
    for idx in 0 .. size - 1:
      realPart[idx] = realPart[idx] / float(size)
      imagPart[idx] = imagPart[idx] / float(size)

proc multiply(first: seq[int], second: seq[int]): seq[int] =
  let need = first.len + second.len - 1
  var size = 1
  while size < need:
    size = size * 2
  var firstRe = newSeq[float](size)
  var firstIm = newSeq[float](size)
  var secondRe = newSeq[float](size)
  var secondIm = newSeq[float](size)
  for idx in 0 .. first.len - 1:
    firstRe[idx] = float(first[idx])
  for idx in 0 .. second.len - 1:
    secondRe[idx] = float(second[idx])
  fft(firstRe, firstIm, false)
  fft(secondRe, secondIm, false)
  for idx in 0 .. size - 1:
    let newRe = firstRe[idx] * secondRe[idx] - firstIm[idx] * secondIm[idx]
    firstIm[idx] = firstRe[idx] * secondIm[idx] + firstIm[idx] * secondRe[idx]
    firstRe[idx] = newRe
  fft(firstRe, firstIm, true)
  var digits = newSeq[int](size + 1)
  for idx in 0 .. size - 1:
    digits[idx] = int(round(firstRe[idx]))
  var carry = 0
  for idx in 0 .. size - 1:
    var value = digits[idx] + carry
    carry = value div digitBase
    digits[idx] = value mod digitBase
  digits[size] = carry
  while digits.len > 1 and digits[digits.len - 1] == 0:
    digits.setLen(digits.len - 1)
  return digits

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendNumber(digits: seq[int]) =
  if digits.len == 1 and digits[0] == 0:
    appendOutput("0")
    return
  let top = digits.len - 1
  appendOutput($digits[top])
  var chunkIdx = top - 1
  while chunkIdx >= 0:
    if digits[chunkIdx] < 10:
      appendOutput("00")
    elif digits[chunkIdx] < 100:
      appendOutput("0")
    appendOutput($digits[chunkIdx])
    chunkIdx -= 1

let caseCount = readCount(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  var startFirst = 0
  var finishFirst = 0
  var startSecond = 0
  var finishSecond = 0
  readToken(inputData, scanPos, startFirst, finishFirst)
  readToken(inputData, scanPos, startSecond, finishSecond)
  let first = toChunks(inputData, startFirst, finishFirst)
  let second = toChunks(inputData, startSecond, finishSecond)
  let product = multiply(first, second)
  appendNumber(product)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

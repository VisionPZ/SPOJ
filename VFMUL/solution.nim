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
    var k = 0
    while right >= start and k < digitGroup:
      chunk += (int(data[right]) - firstDigitValue) * place
      place *= 10
      right -= 1
      k += 1
    result.add chunk
  while result.len > 1 and result[result.len - 1] == 0:
    result.setLen(result.len - 1)

proc fft(re: var seq[float], im: var seq[float], invert: bool) =
  let n = re.len
  var j = 0
  for i in 1 .. n - 1:
    var bit = n div 2
    while (j and bit) != 0:
      j = j xor bit
      bit = bit div 2
    j = j xor bit
    if i < j:
      swap re[i], re[j]
      swap im[i], im[j]
  var len = 2
  while len <= n:
    let angle = (if invert: 2.0 else: -2.0) * piValue / float(len)
    let stepRe = cos(angle)
    let stepIm = sin(angle)
    var i = 0
    while i < n:
      var twiddleRe = 1.0
      var twiddleIm = 0.0
      let half = len div 2
      var k = 0
      while k < half:
        let leftRe = re[i + k]
        let leftIm = im[i + k]
        let rightRe = re[i + k + half] * twiddleRe - im[i + k + half] * twiddleIm
        let rightIm = re[i + k + half] * twiddleIm + im[i + k + half] * twiddleRe
        re[i + k] = leftRe + rightRe
        im[i + k] = leftIm + rightIm
        re[i + k + half] = leftRe - rightRe
        im[i + k + half] = leftIm - rightIm
        let nextRe = twiddleRe * stepRe - twiddleIm * stepIm
        twiddleIm = twiddleRe * stepIm + twiddleIm * stepRe
        twiddleRe = nextRe
        k += 1
      i += len
    len *= 2
  if invert:
    for i in 0 .. n - 1:
      re[i] = re[i] / float(n)
      im[i] = im[i] / float(n)

proc multiply(first: seq[int], second: seq[int]): seq[int] =
  let need = first.len + second.len - 1
  var size = 1
  while size < need:
    size = size * 2
  var firstRe = newSeq[float](size)
  var firstIm = newSeq[float](size)
  var secondRe = newSeq[float](size)
  var secondIm = newSeq[float](size)
  for i in 0 .. first.len - 1:
    firstRe[i] = float(first[i])
  for i in 0 .. second.len - 1:
    secondRe[i] = float(second[i])
  fft(firstRe, firstIm, false)
  fft(secondRe, secondIm, false)
  for i in 0 .. size - 1:
    let newRe = firstRe[i] * secondRe[i] - firstIm[i] * secondIm[i]
    firstIm[i] = firstRe[i] * secondIm[i] + firstIm[i] * secondRe[i]
    firstRe[i] = newRe
  fft(firstRe, firstIm, true)
  var digits = newSeq[int](size + 1)
  for i in 0 .. size - 1:
    digits[i] = int(round(firstRe[i]))
  var carry = 0
  for i in 0 .. size - 1:
    var value = digits[i] + carry
    carry = value div digitBase
    digits[i] = value mod digitBase
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
  var i = top - 1
  while i >= 0:
    if digits[i] < 10:
      appendOutput("00")
    elif digits[i] < 100:
      appendOutput("0")
    appendOutput($digits[i])
    i -= 1

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

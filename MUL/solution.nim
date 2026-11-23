const limbBase = 1000000000
const limbWidth = 9
const naiveCut = 24
const flushBlockBytes = 1 shl 19

var outputBuffer = ""

proc flushBlock() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write(outputBuffer)
    outputBuffer.setLen(0)

proc parseCount(token: string): int =
  var value = 0
  for c in token:
    if c in {'0' .. '9'}:
      value = value * 10 + (c.ord - '0'.ord)
  return value

proc parseLimbs(token: string): seq[int] =
  var limbs: seq[int]
  var value = 0
  var width = 0
  var place = 1
  for index in countdown(token.len - 1, 0):
    if token[index] in {'0' .. '9'}:
      value = value + (token[index].ord - '0'.ord) * place
      place = place * 10
      width = width + 1
      if width == limbWidth:
        limbs.add(value)
        value = 0
        place = 1
        width = 0
  if width > 0:
    limbs.add(value)
  if limbs.len == 0:
    limbs.add(0)
  while limbs.len > 1 and limbs[^1] == 0:
    setLen(limbs, limbs.len - 1)
  return limbs

proc copyRange(source: seq[int], start: int, count: int): seq[int] =
  var result: seq[int]
  for index in 0 ..< count:
    result.add(source[start + index])
  return result

proc multiplyNaive(first: seq[int], second: seq[int]): seq[int] =
  var answer: seq[int]
  setLen(answer, first.len + second.len + 2)
  for outer in 0 ..< first.len:
    var carry = 0
    for inner in 0 ..< second.len:
      let current = answer[outer + inner] + first[outer] * second[inner] + carry
      answer[outer + inner] = current mod limbBase
      carry = current div limbBase
    var position = outer + second.len
    while carry > 0:
      let current = answer[position] + carry
      answer[position] = current mod limbBase
      carry = current div limbBase
      position = position + 1
  return answer

proc normalizeLimbs(limbs: seq[int]): seq[int] =
  var answer = limbs
  var carry = 0
  for index in 0 ..< answer.len:
    let value = answer[index] + carry
    var digit = value mod limbBase
    if digit < 0:
      digit = digit + limbBase
    carry = (value - digit) div limbBase
    answer[index] = digit
  while carry != 0:
    var digit = carry mod limbBase
    if digit < 0:
      digit = digit + limbBase
    answer.add(digit)
    carry = (carry - digit) div limbBase
  while answer.len > 1 and answer[^1] == 0:
    setLen(answer, answer.len - 1)
  return answer

proc combineLimbs(first: seq[int], second: seq[int]): seq[int] =
  let size = max(first.len, second.len)
  if size <= naiveCut:
    return multiplyNaive(first, second)
  let half = (size + 1) div 2
  var firstLow: seq[int]
  var firstHigh: seq[int]
  var secondLow: seq[int]
  var secondHigh: seq[int]
  for index in 0 ..< first.len:
    if index < half:
      firstLow.add(first[index])
    else:
      firstHigh.add(first[index])
  for index in 0 ..< second.len:
    if index < half:
      secondLow.add(second[index])
    else:
      secondHigh.add(second[index])
  var lowProduct = combineLimbs(firstLow, secondLow)
  var highProduct = combineLimbs(firstHigh, secondHigh)
  var firstSum: seq[int]
  var secondSum: seq[int]
  for index in 0 ..< firstLow.len:
    firstSum.add(firstLow[index])
  for index in 0 ..< firstHigh.len:
    if index < firstSum.len:
      firstSum[index] = firstSum[index] + firstHigh[index]
    else:
      firstSum.add(firstHigh[index])
  for index in 0 ..< secondLow.len:
    secondSum.add(secondLow[index])
  for index in 0 ..< secondHigh.len:
    if index < secondSum.len:
      secondSum[index] = secondSum[index] + secondHigh[index]
    else:
      secondSum.add(secondHigh[index])
  var firstSumNorm = normalizeLimbs(firstSum)
  var secondSumNorm = normalizeLimbs(secondSum)
  var middleProduct = combineLimbs(firstSumNorm, secondSumNorm)
  var answer: seq[int]
  setLen(answer, first.len + second.len + 4)
  for index in 0 ..< lowProduct.len:
    answer[index] = answer[index] + lowProduct[index]
    answer[index + half] = answer[index + half] - lowProduct[index]
  for index in 0 ..< middleProduct.len:
    answer[index + half] = answer[index + half] + middleProduct[index]
  for index in 0 ..< highProduct.len:
    answer[index + half] = answer[index + half] - highProduct[index]
    answer[index + half + half] = answer[index + half + half] + highProduct[index]
  return normalizeLimbs(answer)

proc appendBigNumber(limbs: seq[int]) =
  let top = limbs[^1]
  var digits: seq[int]
  var rest = top
  if rest == 0:
    digits.add(0)
  while rest > 0:
    digits.add(rest mod 10)
    rest = rest div 10
  for index in countdown(digits.len - 1, 0):
    outputBuffer.add((digits[index] + '0'.ord).chr)
  for index in countdown(limbs.len - 2, 0):
    var place = limbBase div 10
    while place > 0:
      outputBuffer.add(((limbs[index] div place) mod 10 + '0'.ord).chr)
      place = place div 10

proc appendTokenLimbs(firstToken: string, secondToken: string) =
  let first = parseLimbs(firstToken)
  let second = parseLimbs(secondToken)
  if first.len == 1 and first[0] == 0:
    outputBuffer.add('0')
    outputBuffer.add('\n')
    flushBlock()
    return
  if second.len == 1 and second[0] == 0:
    outputBuffer.add('0')
    outputBuffer.add('\n')
    flushBlock()
    return
  appendBigNumber(normalizeLimbs(combineLimbs(first, second)))
  outputBuffer.add('\n')
  flushBlock()

var line = ""
while stdin.readLine(line):
  let caseCount = parseCount(line)
  for _ in 0 ..< caseCount:
    discard stdin.readLine(line)
    var firstToken = ""
    var secondToken = ""
    var picking = 0
    for c in line:
      if c in {'0' .. '9'}:
        if picking == 0:
          firstToken.add(c)
        else:
          secondToken.add(c)
      else:
        picking = 1
    appendTokenLimbs(firstToken, secondToken)

if outputBuffer.len > 0:
  stdout.write(outputBuffer)

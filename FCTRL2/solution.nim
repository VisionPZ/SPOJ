const baseValue = 1000000000
const limbWidth = 9

var outputBuffer = ""

proc appendNumber(value: int) =
  if value == 0:
    outputBuffer.add('0')
  else:
    var digits: seq[int]
    var rest = value
    while rest > 0:
      digits.add(rest mod 10)
      rest = rest div 10
    for i in countdown(digits.len - 1, 0):
      outputBuffer.add((digits[i] + '0'.ord).chr)

proc appendLimb(limb: int, width: int) =
  var digits: seq[int]
  var rest = limb
  for _ in 0 ..< width:
    digits.add(rest mod 10)
    rest = rest div 10
  for i in countdown(digits.len - 1, 0):
    outputBuffer.add((digits[i] + '0'.ord).chr)

proc multiplyLimbList(limbs: seq[int], factor: int): seq[int] =
  var answer: seq[int]
  var carry = 0
  for i in 0 ..< limbs.len:
    let product = limbs[i] * factor + carry
    answer.add(product mod baseValue)
    carry = product div baseValue
  while carry > 0:
    answer.add(carry mod baseValue)
    carry = carry div baseValue
  return answer

var factorials: seq[seq[int]]
var firstLimbs: seq[int]
firstLimbs.add(1)
factorials.add(firstLimbs)
for value in 1 .. 100:
  factorials.add(multiplyLimbList(factorials[^1], value))

proc appendBigNumber(limbs: seq[int]) =
  appendNumber(limbs[^1])
  for i in countdown(limbs.len - 2, 0):
    appendLimb(limbs[i], limbWidth)

proc parseCount(text: string): int =
  var value = 0
  for c in text:
    if c in {'0' .. '9'}:
      value = value * 10 + (c.ord - '0'.ord)
  return value

var line = ""
while stdin.readLine(line):
  let caseCount = parseCount(line)
  for _ in 0 ..< caseCount:
    discard stdin.readLine(line)
    let number = parseCount(line)
    appendBigNumber(factorials[number])
    outputBuffer.add('\n')

stdout.write(outputBuffer)

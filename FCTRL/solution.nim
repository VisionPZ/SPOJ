const flushBlockBytes = 1 shl 19

var line = ""
var outputBuffer = ""

proc flushBlock() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write(outputBuffer)
    outputBuffer.setLen(0)

proc parseCount(text: string): int =
  var value = 0
  for c in text:
    if c in {'0' .. '9'}:
      value = value * 10 + (c.ord - '0'.ord)
  return value

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

while stdin.readLine(line):
  let caseCount = parseCount(line)
  for _ in 0 ..< caseCount:
    discard stdin.readLine(line)
    let number = parseCount(line)
    var zeros = 0
    var divisor = 5
    while divisor <= number:
      zeros = zeros + number div divisor
      let nextDivisor = divisor * 5
      if nextDivisor < divisor:
        break
      divisor = nextDivisor
    appendNumber(zeros)
    outputBuffer.add('\n')
    flushBlock()

if outputBuffer.len > 0:
  stdout.write(outputBuffer)

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

proc appendReversedSum(firstToken: string, secondToken: string) =
  var digits: seq[int]
  var carry = 0
  let size = max(firstToken.len, secondToken.len)
  for index in 0 ..< size:
    var firstDigit = 0
    if index < firstToken.len:
      firstDigit = firstToken[index].ord - '0'.ord
    var secondDigit = 0
    if index < secondToken.len:
      secondDigit = secondToken[index].ord - '0'.ord
    let value = firstDigit + secondDigit + carry
    digits.add(value mod 10)
    carry = value div 10
  while carry > 0:
    digits.add(carry mod 10)
    carry = carry div 10
  while digits.len > 1 and digits[^1] == 0:
    setLen(digits, digits.len - 1)
  var index = 0
  while index < digits.len and digits[index] == 0:
    index = index + 1
  if index == digits.len:
    outputBuffer.add('0')
  else:
    while index < digits.len:
      outputBuffer.add((digits[index] + '0'.ord).chr)
      index = index + 1

while stdin.readLine(line):
  let pairCount = parseCount(line)
  for _ in 0 ..< pairCount:
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
    appendReversedSum(firstToken, secondToken)
    outputBuffer.add('\n')
    flushBlock()

if outputBuffer.len > 0:
  stdout.write(outputBuffer)

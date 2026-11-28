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
  for i in 0 ..< size:
    var firstDigit = 0
    if i < firstToken.len:
      firstDigit = firstToken[i].ord - '0'.ord
    var secondDigit = 0
    if i < secondToken.len:
      secondDigit = secondToken[i].ord - '0'.ord
    let value = firstDigit + secondDigit + carry
    digits.add(value mod 10)
    carry = value div 10
  while carry > 0:
    digits.add(carry mod 10)
    carry = carry div 10
  while digits.len > 1 and digits[^1] == 0:
    setLen(digits, digits.len - 1)
  var i = 0
  while i < digits.len and digits[i] == 0:
    i = i + 1
  if i == digits.len:
    outputBuffer.add('0')
  else:
    while i < digits.len:
      outputBuffer.add((digits[i] + '0'.ord).chr)
      i = i + 1

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

const flushBlockBytes = 1 shl 17
const limbBase = 1000000000
const limbWidth = 9

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

proc appendPaddedLimb(value: int, width: int) =
  var digits = ""
  var divisor = 100000000
  var digitIndex = 0
  while digitIndex < width:
    digits.add char(48 + ((value div divisor) mod 10))
    divisor = divisor div 10
    digitIndex += 1
  appendOutput(digits)

let maxValue = nextInt(inputData, scanPos)
var limbs = newSeq[int](1)
limbs[0] = 1
var multiplier = 2
while multiplier <= maxValue:
  var carry: int64 = 0
  var limbIndex = 0
  while limbIndex < limbs.len:
    let product = int64(limbs[limbIndex]) * int64(multiplier) + carry
    limbs[limbIndex] = int(product mod int64(limbBase))
    carry = product div int64(limbBase)
    limbIndex += 1
  while carry > 0:
    limbs.add(int(carry mod int64(limbBase)))
    carry = carry div int64(limbBase)
  multiplier += 1

var topLimbIndex = limbs.len - 1
appendOutput($limbs[topLimbIndex])
topLimbIndex -= 1
while topLimbIndex >= 0:
  appendPaddedLimb(limbs[topLimbIndex], limbWidth)
  topLimbIndex -= 1
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

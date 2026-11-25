const flushBlockBytes = 1 shl 17
const limbBase = 1000000000

type BigValue = seq[int32]

proc multiplySmall(value: var BigValue, factor: int32) =
  var carry: int64 = 0
  for limbIndex in 0 .. value.len - 1:
    let combined = int64(value[limbIndex]) * int64(factor) + carry
    value[limbIndex] = int32(combined mod int64(limbBase))
    carry = combined div int64(limbBase)
  while carry > 0:
    value.add int32(carry mod int64(limbBase))
    carry = carry div int64(limbBase)

proc smallPower(base: int32, exponent: int): BigValue =
  var product: BigValue = @[int32(1)]
  for step in 1 .. exponent:
    multiplySmall(product, base)
  return product

proc scaledSmallPower(base: int32, exponent: int, factor: int32): BigValue =
  var product: BigValue = @[int32(1)]
  for step in 1 .. exponent:
    multiplySmall(product, base)
  multiplySmall(product, factor)
  return product

proc compareBig(left: BigValue, right: BigValue): int =
  if left.len > right.len: return 1
  if left.len < right.len: return -1
  for limbIndex in countdown(left.len - 1, 0):
    if left[limbIndex] > right[limbIndex]: return 1
    if left[limbIndex] < right[limbIndex]: return -1
  return 0

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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let principal = nextInt(inputData, scanPos)
  discard principal
  let years = nextInt(inputData, scanPos)
  let simpleRate = nextInt(inputData, scanPos)
  let compoundRate = nextInt(inputData, scanPos)
  let compoundSide = smallPower(int32(100 + compoundRate), years)
  let simpleSide = scaledSmallPower(int32(100), years - 1, int32(100 + simpleRate * years))
  let relation = compareBig(compoundSide, simpleSide)
  if relation > 0:
    appendOutput("Bank 1")
  elif relation < 0:
    appendOutput("Bank 2")
  else:
    appendOutput("Confused huh!")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const trunkLimit = 100002000
const riverSeeds: array[3, int] = [1, 3, 9]
const residueBits = 3

proc digitSum(value: int): int =
  var remaining = value
  var total = 0
  while remaining > 0:
    total += remaining mod 10
    remaining = remaining div 10
  return total

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var riverBits: array[3, seq[byte]]
for riverIndex in 0 .. 2:
  riverBits[riverIndex] = newSeq[byte]((trunkLimit shr residueBits) + 1)
  var stoneValue = riverSeeds[riverIndex]
  while stoneValue <= trunkLimit:
    let byteIndex = stoneValue shr residueBits
    riverBits[riverIndex][byteIndex] = riverBits[riverIndex][byteIndex] or byte(1 shl (stoneValue and 7))
    stoneValue += digitSum(stoneValue)

proc isOnRiver(riverIndex: int, stoneValue: int): bool =
  let byteIndex = stoneValue shr residueBits
  if byteIndex >= riverBits[riverIndex].len:
    return false
  return (riverBits[riverIndex][byteIndex] and byte(1 shl (stoneValue and 7))) != 0

proc riverIndexFor(value: int): int =
  let remainder = value mod 9
  if remainder == 1 or remainder == 2 or remainder == 4 or remainder == 5 or remainder == 7 or remainder == 8:
    return 0
  if remainder == 3 or remainder == 6:
    return 1
  return 2

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rememberedNumber = nextInt(inputData, scanPos)
  let chosenRiver = riverIndexFor(rememberedNumber)
  var stoneValue = rememberedNumber
  while not isOnRiver(chosenRiver, stoneValue):
    stoneValue += digitSum(stoneValue)
  appendOutput($riverSeeds[chosenRiver])
  outputBuffer.add ' '
  appendOutput($stoneValue)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

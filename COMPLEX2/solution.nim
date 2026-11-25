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

proc limbText(value: int, padded: bool): string =
  let rawText = $value
  if not padded:
    return rawText
  result = ""
  var zeroCount = limbWidth - rawText.len
  while zeroCount > 0:
    result.add '0'
    zeroCount -= 1
  result.add rawText

proc powerText(baseValue: int, exponentValue: int): string =
  var limbs: seq[int] = @[1]
  for stepIndex in 1 .. exponentValue:
    var carry = 0
    for limbIndex in 0 .. limbs.len - 1:
      let productValue = limbs[limbIndex] * baseValue + carry
      limbs[limbIndex] = productValue mod limbBase
      carry = productValue div limbBase
    while carry > 0:
      limbs.add carry mod limbBase
      carry = carry div limbBase
  limbs[0] = limbs[0] - 1
  var borrowIndex = 0
  while limbs[borrowIndex] < 0:
    limbs[borrowIndex] = limbs[borrowIndex] + limbBase
    borrowIndex += 1
    limbs[borrowIndex] = limbs[borrowIndex] - 1
  while limbs.len > 1 and limbs[limbs.len - 1] == 0:
    limbs.setLen(limbs.len - 1)
  result = limbText(limbs[limbs.len - 1], false)
  var limbIndex = limbs.len - 2
  while limbIndex >= 0:
    result.add limbText(limbs[limbIndex], true)
    limbIndex -= 1
  return result

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let baseValue = nextInt(inputData, scanPos)
  let exponentValue = nextInt(inputData, scanPos)
  appendOutput(powerText(baseValue, exponentValue))
  appendOutput("/")
  appendOutput($(baseValue - 1))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const modulusValue: int64 = 1000000007

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

proc powerMod(baseValue: int64, exponentValue: int64): int64 =
  var baseNow = baseValue mod modulusValue
  var exponentNow = exponentValue
  var resultValue: int64 = 1
  while exponentNow > 0:
    if exponentNow mod 2 == 1:
      resultValue = (resultValue * baseNow) mod modulusValue
    baseNow = (baseNow * baseNow) mod modulusValue
    exponentNow = exponentNow div 2
  return resultValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
let inverseTwentyFour = powerMod(24, modulusValue - 2)
for caseIndex in 0 .. caseCount - 1:
  let vertexCount = nextInt(inputData, scanPos)
  if vertexCount < 4:
    appendOutput("0")
  else:
    var productValue: int64 = int64(vertexCount) mod modulusValue
    productValue = (productValue * int64(vertexCount - 1)) mod modulusValue
    productValue = (productValue * int64(vertexCount - 2)) mod modulusValue
    productValue = (productValue * int64(vertexCount - 3)) mod modulusValue
    appendOutput($(productValue * inverseTwentyFour mod modulusValue))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

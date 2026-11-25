const flushBlockBytes = 1 shl 17
const splitStep = 1000

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
  let factorialLimit = nextInt(inputData, scanPos)
  let modulusValue = nextInt(inputData, scanPos)
  if modulusValue == 1:
    appendOutput("0\n")
    continue
  var productValue: int64 = 1
  var factorCursor = 1
  while factorCursor <= factorialLimit:
    let highPart = factorCursor div splitStep
    let lowPart = factorCursor mod splitStep
    let lowProduct = (productValue * int64(lowPart)) mod int64(modulusValue)
    let highProduct = (productValue * int64(highPart)) mod int64(modulusValue)
    productValue = (lowProduct + highProduct * int64(splitStep)) mod int64(modulusValue)
    if productValue == 0:
      break
    factorCursor += 1
  appendOutput($productValue & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0

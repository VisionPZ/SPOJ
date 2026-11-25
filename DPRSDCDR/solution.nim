const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let ctCount = nextInt(inputData, scanPos)
  let labCount = nextInt(inputData, scanPos)
  let hoursPerCt = nextInt(inputData, scanPos)
  let hoursPerLab = nextInt(inputData, scanPos)
  let classHours = nextInt(inputData, scanPos)
  let occupiedHours = ctCount * hoursPerCt + labCount * hoursPerLab + classHours
  if occupiedHours <= 11:
    appendOutput("Khushi\n")
  else:
    appendOutput("Hotash\n")
stdout.write outputBuffer

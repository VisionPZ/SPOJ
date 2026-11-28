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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let bucketBase = nextInt(inputData, scanPos)
let bucketExponent = nextInt(inputData, scanPos)
let roomCount = nextInt(inputData, scanPos)
var powerBase = bucketBase mod roomCount
var powerResult = 1 mod roomCount
var exponentCursor = bucketExponent
while exponentCursor > 0:
  if (exponentCursor and 1) == 1:
    powerResult = (powerResult * powerBase) mod roomCount
  powerBase = (powerBase * powerBase) mod roomCount
  exponentCursor = exponentCursor shr 1
let extraBuckets = powerResult
var mangoRemainder: int64 = 0
if extraBuckets > 0:
  let partitionCount = nextInt(inputData, scanPos)
  for partitionIndex in 0 .. partitionCount - 1:
    let mangoAmount = nextInt(inputData, scanPos)
    mangoRemainder = (mangoRemainder + int64(mangoAmount) mod int64(extraBuckets)) mod int64(extraBuckets)
appendOutput($extraBuckets & " " & $mangoRemainder & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0

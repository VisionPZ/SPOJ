const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, pos: var int): int =
  while pos < inputData.len and inputData[pos] != '-' and
        (inputData[pos] < '0' or inputData[pos] > '9'):
    pos += 1
  var signValue = 1
  if pos < inputData.len and inputData[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < inputData.len and inputData[pos] >= '0' and inputData[pos] <= '9':
    value = value * 10 + int(inputData[pos]) - 48
    pos += 1
  return signValue * value

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var pos = 0
let caseCount = nextInt(inputData, pos)
var outputBuffer = ""
for caseIndex in 1 .. caseCount:
  let planetCount = nextInt(inputData, pos)
  var bestDistance: int64 = -1
  var bestIndex = 1
  for planetIndex in 1 .. planetCount:
    let xCoord = nextInt(inputData, pos)
    let yCoord = nextInt(inputData, pos)
    let distance = int64(xCoord) * int64(xCoord) + int64(yCoord) * int64(yCoord)
    if distance > bestDistance:
      bestDistance = distance
      bestIndex = planetIndex
  outputBuffer.add "Case "
  outputBuffer.add $caseIndex
  outputBuffer.add ": "
  outputBuffer.add $bestIndex
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for i in 0..<caseCount:
  let vertexCount = nextInt(inputData, scanPos)
  let triangleCount = vertexCount - 2
  let blackFirst = nextInt(inputData, scanPos)
  let blackSecond = nextInt(inputData, scanPos)
  let blackThird = nextInt(inputData, scanPos)
  var blackDegree = 0
  for j in 1..<triangleCount:
    var sharedCount = 0
    for k in 0..<3:
      let vertex = nextInt(inputData, scanPos)
      if vertex == blackFirst or vertex == blackSecond or vertex == blackThird:
        sharedCount += 1
    if sharedCount >= 2:
      blackDegree += 1
  if blackDegree <= 1 or vertexCount mod 2 == 0:
    appendOutput("YES\n")
  else:
    appendOutput("NO\n")

stdout.write outputBuffer
outputBuffer.setLen 0

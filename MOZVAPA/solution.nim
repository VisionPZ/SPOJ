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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var word = ""
  while pos < data.len and data[pos] > ' ':
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let bracketCount = nextInt(inputData, scanPos)
  let bracketString = nextToken(inputData, scanPos)
  var openPrefix = newSeq[int](bracketCount + 1)
  openPrefix[0] = 0
  for position in 0 .. bracketCount - 1:
    openPrefix[position + 1] = openPrefix[position]
    if bracketString[position] == '(':
      openPrefix[position + 1] += 1
  let queryCount = nextInt(inputData, scanPos)
  for queryIndex in 0 .. queryCount - 1:
    let leftEnd = nextInt(inputData, scanPos)
    let rightEnd = nextInt(inputData, scanPos)
    let spanLength = rightEnd - leftEnd + 1
    let openCount = openPrefix[rightEnd] - openPrefix[leftEnd - 1]
    if spanLength mod 2 == 0 and openCount * 2 == spanLength:
      appendOutput("YES\n")
    else:
      appendOutput("NO\n")
stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
var inputLines = newSeq[string]()
while readLine(stdin, inputLine):
  inputLines.add inputLine
  inputData.add inputLine
  inputData.add '\n'

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

proc composePermutations(leftPerm: seq[int], rightPerm: seq[int]): seq[int] =
  let count = leftPerm.len
  var composed = newSeq[int](count)
  for index in 0 .. count - 1:
    composed[index] = leftPerm[rightPerm[index]]
  return composed

var linePos = 0
while linePos < inputLines.len:
  var headerPos = 0
  let stringLength = nextInt(inputLines[linePos], headerPos)
  let repeatCount = nextInt(inputLines[linePos], headerPos)
  linePos += 1
  if stringLength == 0 and repeatCount == 0:
    break
  var permPos = 0
  var forwardPerm = newSeq[int](stringLength)
  for index in 0 .. stringLength - 1:
    forwardPerm[index] = nextInt(inputLines[linePos], permPos) - 1
  linePos += 1
  let encodedText = inputLines[linePos]
  linePos += 1
  var powerPerm = newSeq[int](stringLength)
  for index in 0 .. stringLength - 1:
    powerPerm[index] = index
  var basePerm = forwardPerm
  var remaining = repeatCount
  while remaining > 0:
    if (remaining and 1) == 1:
      powerPerm = composePermutations(powerPerm, basePerm)
    basePerm = composePermutations(basePerm, basePerm)
    remaining = remaining shr 1
  var decodedText = newSeq[char](stringLength)
  for index in 0 .. stringLength - 1:
    decodedText[powerPerm[index]] = encodedText[index]
  for index in 0 .. stringLength - 1:
    appendOutput($decodedText[index])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

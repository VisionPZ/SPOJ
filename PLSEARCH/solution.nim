const flushBlockBytes = 1 shl 17
const turnCount = 4

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc directionCode(fromX: int, fromY: int, toX: int, toY: int): int =
  if toX > fromX:
    return 0
  if toY > fromY:
    return 1
  if toX < fromX:
    return 2
  return 3

proc appendFixedLength(sequence: var string, length: int) =
  var divisor = 10000
  while divisor > 0:
    sequence.add chr(48 + (length div divisor) mod 10)
    divisor = divisor div 10

proc encodeLine(vertexCount: int): string =
  var previousX = nextInt(inputData, scanPos)
  var previousY = nextInt(inputData, scanPos)
  var sequence = ""
  for vertexIndex in 1 .. vertexCount - 1:
    let currentX = nextInt(inputData, scanPos)
    let currentY = nextInt(inputData, scanPos)
    let stepLength = abs(currentX - previousX) + abs(currentY - previousY)
    sequence.add chr(48 + directionCode(previousX, previousY, currentX, currentY))
    appendFixedLength(sequence, stepLength)
    previousX = currentX
    previousY = currentY
  return sequence

proc rotateSequence(sequence: string, shift: int): string =
  var rotated = ""
  var index = 0
  while index < sequence.len:
    rotated.add chr(48 + ((int(sequence[index]) - 48 + shift) mod turnCount))
    for offset in 1 .. 5:
      rotated.add sequence[index + offset]
    index += 6
  return rotated

proc reverseSequence(sequence: string): string =
  var reversed = ""
  var index = sequence.len - 6
  while index >= 0:
    var code = int(sequence[index]) - 48
    code = (code + 2) mod turnCount
    reversed.add chr(48 + code)
    for offset in 1 .. 5:
      reversed.add sequence[index + offset]
    index -= 6
  return reversed

proc sameShape(reference: string, candidate: string): bool =
  if candidate.len != reference.len:
    return false
  for shift in 0 .. turnCount - 1:
    if rotateSequence(candidate, shift) == reference:
      return true
  let reversedCandidate = reverseSequence(candidate)
  for shift in 0 .. turnCount - 1:
    if rotateSequence(reversedCandidate, shift) == reference:
      return true
  return false

while true:
  let lineCount = nextInt(inputData, scanPos)
  if lineCount == 0:
    break
  let templateSequence = encodeLine(nextInt(inputData, scanPos))
  for lineIndex in 1 .. lineCount:
    let candidateSequence = encodeLine(nextInt(inputData, scanPos))
    if sameShape(templateSequence, candidateSequence):
      appendOutput($lineIndex)
      outputBuffer.add '\n'
  appendOutput("+++++\n")
stdout.write outputBuffer
outputBuffer.setLen 0

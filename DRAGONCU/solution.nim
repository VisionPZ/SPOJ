const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
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

var fullX = newSeq[int](31)
var fullY = newSeq[int](31)
fullX[0] = 1
fullY[0] = 0
fullX[1] = 1
fullY[1] = 1
for levelIndex in 2 .. 30:
  fullX[levelIndex] = fullX[levelIndex - 1] - fullY[levelIndex - 1]
  fullY[levelIndex] = fullX[levelIndex - 1] + fullY[levelIndex - 1]

proc mirrorWalk(level: int, steps: int): tuple[x: int, y: int]

proc forwardWalk(level: int, steps: int): tuple[x: int, y: int] =
  if steps == 0:
    return (0, 0)
  if level == 0:
    return (steps, 0)
  if level == 1:
    if steps == 1:
      return (1, 0)
    return (1, 1)
  let half = 1 shl (level - 1)
  if steps <= half:
    return forwardWalk(level - 1, steps)
  let rest = mirrorWalk(level - 1, steps - half)
  return (fullX[level - 1] - rest.x, fullY[level - 1] - rest.y)

proc mirrorWalk(level: int, steps: int): tuple[x: int, y: int] =
  if steps == 0:
    return (0, 0)
  if level == 0:
    return (steps, 0)
  if level == 1:
    if steps == 1:
      return (1, 0)
    return (1, -1)
  let half = 1 shl (level - 1)
  if steps <= half:
    return forwardWalk(level - 1, steps)
  let rest = mirrorWalk(level - 1, steps - half)
  return (fullX[level - 1] + rest.x, fullY[level - 1] + rest.y)

var seconds = nextInt(inputData, scanPos)
while seconds != -1:
  let location = forwardWalk(30, seconds)
  appendOutput("(" & $location.x & "," & $location.y & ")\n")
  seconds = nextInt(inputData, scanPos)

stdout.write outputBuffer
outputBuffer.setLen 0

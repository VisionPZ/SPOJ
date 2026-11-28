const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextLine(data: string, pos: var int): string =
  var line = ""
  while pos < data.len and data[pos] != '\n':
    if data[pos] != '\r':
      line.add data[pos]
    pos += 1
  if pos < data.len:
    pos += 1
  return line

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

proc vineMonkeys(data: string, startPos: int, endPos: int): int64 =
  var bestCount: int64 = 1
  var pos = startPos
  while pos < endPos:
    if data[pos] == '[':
      let openPos = pos
      var depth = 0
      var closePos = -1
      while pos < endPos:
        if data[pos] == '[':
          depth += 1
        elif data[pos] == ']':
          depth -= 1
          if depth == 0:
            closePos = pos
            break
        pos += 1
      let innerCount = vineMonkeys(data, openPos + 1, closePos)
      let junctionCount = 2 * innerCount
      if junctionCount > bestCount:
        bestCount = junctionCount
      pos = closePos + 1
    else:
      pos += 1
  return bestCount

var headerPos = 0
let header = nextLine(inputData, headerPos)
scanPos = headerPos
var numberPos = 0
let caseCount = nextInt(header, numberPos)
for caseIndex in 1 .. caseCount:
  let vine = nextLine(inputData, scanPos)
  let monkeyCount = vineMonkeys(vine, 0, vine.len)
  var line = $caseIndex & " " & $monkeyCount & "\n"
  appendOutput(line)

stdout.write outputBuffer
outputBuffer.setLen 0

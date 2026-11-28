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

proc findFrom(data: string, marker: string, startPos: int): int =
  if marker.len == 0:
    return startPos
  var searchPos = startPos
  while searchPos + marker.len <= data.len:
    var matched = true
    var offset = 0
    while offset < marker.len:
      if data[searchPos + offset] != marker[offset]:
        matched = false
        break
      offset += 1
    if matched:
      return searchPos
    searchPos += 1
  return -1

proc movePastMarker(data: string, pos: var int, marker: string) =
  let foundAt = findFrom(data, marker, pos)
  if foundAt >= 0:
    pos = foundAt + marker.len
  else:
    pos = data.len

proc readOptionalNumber(data: string, pos: var int): int =
  while pos < data.len and data[pos] == ' ':
    pos += 1
  if pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    return nextInt(data, pos)
  return -1

proc readDetailText(data: string, pos: var int): string =
  while pos < data.len and data[pos] == ' ':
    pos += 1
  var textEnd = pos
  while textEnd < data.len and data[textEnd] != '\n' and data[textEnd] != '\r':
    textEnd += 1
  let nextRecord = findFrom(data, "TYPE 1:", pos)
  if nextRecord >= 0 and nextRecord < textEnd:
    textEnd = nextRecord
  var detail = ""
  if textEnd > pos:
    detail = data.substr(pos, textEnd - 1)
  while detail.len > 0 and detail[detail.len - 1] == ' ':
    detail.setLen(detail.len - 1)
  pos = textEnd
  return detail

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  movePastMarker(inputData, scanPos, "TYPE 1:")
  let firstNumber = nextInt(inputData, scanPos)
  movePastMarker(inputData, scanPos, "TYPE 2:")
  let secondNumber = readOptionalNumber(inputData, scanPos)
  movePastMarker(inputData, scanPos, "TYPE 3:")
  let thirdNumber = readOptionalNumber(inputData, scanPos)
  movePastMarker(inputData, scanPos, "TYPE details:")
  let detailText = readDetailText(inputData, scanPos)
  appendOutput("(" & $firstNumber & ",")
  if secondNumber < 0:
    appendOutput("NULL")
  else:
    appendOutput($secondNumber)
  appendOutput(",")
  if thirdNumber < 0:
    appendOutput("NULL")
  else:
    appendOutput($thirdNumber)
  appendOutput(",'" & detailText & "')")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

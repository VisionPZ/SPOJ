const flushBlockBytes = 1 shl 17
const totalMinutes = 1440
const digitSegments: array[10, array[7, int]] = [
  [6, 9, 9, 0, 9, 9, 6],
  [0, 8, 8, 0, 8, 8, 0],
  [6, 8, 8, 6, 1, 1, 6],
  [6, 8, 8, 6, 8, 8, 6],
  [0, 9, 9, 6, 8, 8, 0],
  [6, 1, 1, 6, 8, 8, 6],
  [6, 1, 1, 6, 9, 9, 6],
  [6, 8, 8, 0, 8, 8, 0],
  [6, 9, 9, 6, 9, 9, 6],
  [6, 9, 9, 6, 8, 8, 6]
]
const digitStarts = [0, 5, 12, 17]
const separatorColumns = [4, 9, 11, 16]
const middleRows = [1, 2, 4, 5]
const middleColumns = [1, 2, 6, 7, 13, 14, 18, 19]
const endRows = [0, 3, 6]
const endColumns = [0, 3, 5, 8, 12, 15, 17, 20]
const colonRows = [0, 1, 3, 5, 6]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
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

proc nextLine(data: string, pos: var int): string =
  var start = pos
  while start < data.len and data[start] == '\n':
    start += 1
  var finish = start
  while finish < data.len and data[finish] != '\n':
    finish += 1
  result = ""
  for index in start .. finish - 1:
    result.add data[index]
  pos = finish
  if pos < data.len:
    pos += 1

var actualDisplays: array[totalMinutes, array[7, array[21, bool]]]
for minute in 0 .. totalMinutes - 1:
  let hour = minute div 60
  let minutePart = minute mod 60
  let digits = [hour div 10, hour mod 10, minutePart div 10, minutePart mod 10]
  for row in 0 .. 6:
    for column in 0 .. 20:
      actualDisplays[minute][row][column] = false
  for digitIndex in 0 .. 3:
    if digitIndex == 0 and digits[0] == 0:
      continue
    let digit = digits[digitIndex]
    let startColumn = digitStarts[digitIndex]
    for row in 0 .. 6:
      let mask = digitSegments[digit][row]
      for offset in 0 .. 3:
        if (mask and (1 shl offset)) != 0:
          actualDisplays[minute][row][startColumn + offset] = true
  actualDisplays[minute][2][10] = true
  actualDisplays[minute][4][10] = true

var alwaysOff: array[7, array[21, bool]]
for row in 0 .. 6:
  for column in 0 .. 20:
    alwaysOff[row][column] = false
for row in 0 .. 6:
  for index in 0 .. separatorColumns.len - 1:
    alwaysOff[row][separatorColumns[index]] = true
for rowIndex in 0 .. middleRows.len - 1:
  for columnIndex in 0 .. middleColumns.len - 1:
    alwaysOff[middleRows[rowIndex]][middleColumns[columnIndex]] = true
for rowIndex in 0 .. endRows.len - 1:
  for columnIndex in 0 .. endColumns.len - 1:
    alwaysOff[endRows[rowIndex]][endColumns[columnIndex]] = true
for index in 0 .. colonRows.len - 1:
  alwaysOff[colonRows[index]][10] = true

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var linePos = 0
while true:
  let headerLine = nextLine(inputData, linePos)
  if headerLine.len == 0:
    break
  var headerPos = 0
  let frameCount = nextInt(headerLine, headerPos)
  var clocks = newSeq[array[7, array[21, bool]]](frameCount)
  for frame in 0 .. frameCount - 1:
    for row in 0 .. 6:
      let imageLine = nextLine(inputData, linePos)
      for column in 0 .. 20:
        clocks[frame][row][column] = imageLine[column] == 'X'
  var answer: array[7, array[21, char]]
  for row in 0 .. 6:
    for column in 0 .. 20:
      var seenOn = false
      var seenOff = false
      for frame in 0 .. frameCount - 1:
        if clocks[frame][row][column]:
          seenOn = true
        else:
          seenOff = true
      if seenOn and seenOff:
        answer[row][column] = 'W'
      elif seenOn and not alwaysOff[row][column]:
        answer[row][column] = '1'
      elif seenOff and not alwaysOff[row][column]:
        answer[row][column] = '0'
      else:
        answer[row][column] = '.'
  var possible = false
  for startMinute in 0 .. totalMinutes - 1:
    var matches: array[7, array[21, int]]
    for row in 0 .. 6:
      for column in 0 .. 20:
        matches[row][column] = 0
    for frame in 0 .. frameCount - 1:
      let minute = (startMinute + frame) mod totalMinutes
      for row in 0 .. 6:
        for column in 0 .. 20:
          if actualDisplays[minute][row][column] == clocks[frame][row][column]:
            matches[row][column] += 1
    var valid = true
    for row in 0 .. 6:
      for column in 0 .. 20:
        if answer[row][column] == 'W' and matches[row][column] != frameCount:
          valid = false
    if not valid:
      continue
    for row in 0 .. 6:
      for column in 0 .. 20:
        if (answer[row][column] == '1' or answer[row][column] == '0') and
            matches[row][column] == frameCount:
          answer[row][column] = '?'
    possible = true
  if not possible:
    appendOutput("impossible")
    outputBuffer.add '\n'
  else:
    for row in 0 .. 6:
      for column in 0 .. 20:
        appendOutput($answer[row][column])
      outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

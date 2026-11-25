import strutils

const flushBlockBytes = 1 shl 17
const rowCells = 128

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc findCrossIndex(horizontalWord: string, verticalWord: string): (int, int) =
  var horizontalIndex = 0
  while horizontalIndex < horizontalWord.len:
    var verticalIndex = 0
    while verticalIndex < verticalWord.len:
      if horizontalWord[horizontalIndex] == verticalWord[verticalIndex]:
        return (horizontalIndex, verticalIndex)
      verticalIndex += 1
    horizontalIndex += 1
  return (-1, -1)

proc appendCrossRow(leftColumn: int, leftCharacter: char, rightColumn: int, rightCharacter: char) =
  var row = repeat(' ', rowCells)
  var lastColumn = -1
  if leftCharacter != chr(0):
    row[leftColumn] = leftCharacter
    lastColumn = leftColumn
  if rightCharacter != chr(0):
    row[rightColumn] = rightCharacter
    if rightColumn > lastColumn:
      lastColumn = rightColumn
  if lastColumn >= 0:
    appendOutput(row[0 .. lastColumn])
  appendOutput("\n")

var scanPos = 0
var setNumber = 0
while scanPos < inputData.len:
  var lineStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] != '\n':
    scanPos += 1
  var lineEnd = scanPos
  if scanPos < inputData.len:
    scanPos += 1
  while lineEnd > lineStart and (inputData[lineEnd - 1] == '\r' or inputData[lineEnd - 1] == ' ' or inputData[lineEnd - 1] == '\t'):
    lineEnd -= 1
  if lineEnd == lineStart:
    continue
  if lineEnd - lineStart == 1 and inputData[lineStart] == '#':
    break

  var words = newSeq[string](0)
  var tokenStart = lineStart
  while tokenStart < lineEnd and words.len < 4:
    while tokenStart < lineEnd and (inputData[tokenStart] == ' ' or inputData[tokenStart] == '\t'):
      tokenStart += 1
    var tokenEnd = tokenStart
    while tokenEnd < lineEnd and inputData[tokenEnd] != ' ' and inputData[tokenEnd] != '\t':
      tokenEnd += 1
    if tokenEnd > tokenStart:
      words.add inputData[tokenStart ..< tokenEnd]
    tokenStart = tokenEnd
  if words.len != 4:
    continue

  if setNumber > 0:
    appendOutput("\n")
  setNumber += 1
  appendOutput(inputData[lineStart ..< lineEnd])
  appendOutput("\n")

  let firstCross = findCrossIndex(words[0], words[1])
  let secondCross = findCrossIndex(words[2], words[3])
  if firstCross[0] < 0 or secondCross[0] < 0:
    appendOutput("Unable to make two crosses\n")
    continue

  let firstColumn = firstCross[0]
  let firstVerticalIndex = firstCross[1]
  let secondColumn = secondCross[0]
  let secondVerticalIndex = secondCross[1]
  let rightColumn = words[0].len + 3 + secondColumn

  let aboveCount = max(firstVerticalIndex, secondVerticalIndex)
  var rowOffset = 0
  while rowOffset < aboveCount:
    let firstIndex = rowOffset - (aboveCount - firstVerticalIndex)
    let secondIndex = rowOffset - (aboveCount - secondVerticalIndex)
    let leftCharacter = if firstIndex >= 0: words[1][firstIndex] else: chr(0)
    let rightCharacter = if secondIndex >= 0: words[3][secondIndex] else: chr(0)
    appendCrossRow(firstColumn, leftCharacter, rightColumn, rightCharacter)
    rowOffset += 1

  appendOutput(words[0])
  appendOutput("   ")
  appendOutput(words[2])
  appendOutput("\n")

  let belowFirst = words[1].len - firstVerticalIndex - 1
  let belowSecond = words[3].len - secondVerticalIndex - 1
  let belowCount = max(belowFirst, belowSecond)
  rowOffset = 0
  while rowOffset < belowCount:
    let firstIndex = firstVerticalIndex + 1 + rowOffset
    let secondIndex = secondVerticalIndex + 1 + rowOffset
    let leftCharacter = if firstIndex < words[1].len: words[1][firstIndex] else: chr(0)
    let rightCharacter = if secondIndex < words[3].len: words[3][secondIndex] else: chr(0)
    appendCrossRow(firstColumn, leftCharacter, rightColumn, rightCharacter)
    rowOffset += 1
stdout.write outputBuffer
outputBuffer.setLen 0

import tables

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

proc nextLine(data: string, pos: var int): string =
  if pos >= data.len:
    return ""
  var lineEnd = pos
  while lineEnd < data.len and data[lineEnd] != '\n':
    lineEnd += 1
  var lineText = ""
  if lineEnd > pos:
    lineText = data.substr(pos, lineEnd - 1)
  pos = lineEnd + 1
  if lineText.len > 0 and lineText[lineText.len - 1] == '\r':
    lineText.setLen(lineText.len - 1)
  return lineText

proc skipLine(data: string, pos: var int) =
  discard nextLine(data, pos)

proc translateLyric(lineText: string, wordMap: Table[string, string]): string =
  if lineText.len == 0:
    return ""
  var translated = ""
  var tokenStart = 0
  while tokenStart < lineText.len:
    var tokenEnd = tokenStart
    while tokenEnd < lineText.len and lineText[tokenEnd] != ' ':
      tokenEnd += 1
    if translated.len > 0:
      translated.add ' '
    let wordToken = lineText.substr(tokenStart, tokenEnd - 1)
    if wordMap.hasKey(wordToken):
      translated.add wordMap[wordToken]
    else:
      translated.add wordToken
    tokenStart = tokenEnd + 1
  return translated

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let wordCount = nextInt(inputData, scanPos)
  let lineCount = nextInt(inputData, scanPos)
  skipLine(inputData, scanPos)
  var wordMap = initTable[string, string]()
  for wordIndex in 0 .. wordCount - 1:
    let japaneseWord = nextLine(inputData, scanPos)
    let portugueseText = nextLine(inputData, scanPos)
    wordMap[japaneseWord] = portugueseText
  for lineIndex in 0 .. lineCount - 1:
    let lyricLine = nextLine(inputData, scanPos)
    appendOutput(translateLyric(lyricLine, wordMap))
    outputBuffer.add '\n'
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17

type Token = object
  kind: int
  text: string

type Piece = object
  kind: int
  text: string

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

proc isSeparator(character: char): bool =
  return character == ' ' or character == '\n' or character == '\r' or
         character == '\t'

var sentences = newSeq[seq[Token]](0)
var currentSentence = newSeq[Token](0)
var scanPos = 0

while scanPos < inputData.len:
  let currentChar = inputData[scanPos]
  if isSeparator(currentChar):
    scanPos += 1
  elif currentChar == '.':
    sentences.add currentSentence
    currentSentence = newSeq[Token](0)
    scanPos += 1
  elif currentChar == '"' or currentChar == '\'':
    let quoteChar = currentChar
    scanPos += 1
    var stringText = ""
    while scanPos < inputData.len and inputData[scanPos] != quoteChar:
      stringText.add inputData[scanPos]
      scanPos += 1
    if scanPos < inputData.len:
      scanPos += 1
    currentSentence.add Token(kind: 1, text: stringText)
  else:
    var wordText = ""
    while scanPos < inputData.len:
      let letter = inputData[scanPos]
      if isSeparator(letter) or letter == '.' or letter == '-' or
         letter == '"' or letter == '\'':
        break
      wordText.add letter
      scanPos += 1
    var lowered = ""
    for character in wordText:
      if character >= 'A' and character <= 'Z':
        lowered.add chr(int(character) + 32)
      else:
        lowered.add character
    currentSentence.add Token(kind: 0, text: lowered)
    if scanPos < inputData.len and inputData[scanPos] == '-':
      scanPos += 1

if currentSentence.len > 0:
  sentences.add currentSentence

proc wordValue(wordText: string): int =
  case wordText
  of "zero": return 0
  of "one": return 1
  of "two": return 2
  of "three": return 3
  of "four": return 4
  of "five": return 5
  of "six": return 6
  of "seven": return 7
  of "eight": return 8
  of "nine": return 9
  of "ten": return 10
  of "eleven": return 11
  of "twelve": return 12
  of "thirteen": return 13
  of "fourteen": return 14
  of "fifteen": return 15
  of "sixteen": return 16
  of "seventeen": return 17
  of "eighteen": return 18
  of "nineteen": return 19
  of "twenty": return 20
  of "thirty": return 30
  of "forty": return 40
  of "fifty": return 50
  of "sixty": return 60
  of "seventy": return 70
  of "eighty": return 80
  of "ninety": return 90
  else: return -1

proc isTensWord(wordText: string): bool =
  let value = wordValue(wordText)
  return value >= 20 and value mod 10 == 0

proc parseNumberWord(sentence: seq[Token], pos: var int): int =
  if pos >= sentence.len:
    return 0
  let firstValue = wordValue(sentence[pos].text)
  pos += 1
  if isTensWord(sentence[pos - 1].text) and pos < sentence.len:
    let secondValue = wordValue(sentence[pos].text)
    if secondValue > 0 and secondValue < 10:
      pos += 1
      return firstValue + secondValue
  return firstValue

proc designatorKind(wordText: string): int =
  case wordText
  of "number", "numbers": return 0
  of "string", "strings": return 1
  of "space", "spaces": return 2
  else: return -1

proc isPluralDesignator(wordText: string): bool =
  return wordText == "numbers" or wordText == "strings" or wordText == "spaces"

proc needsSpace(previousKind: int, currentKind: int): bool =
  if previousKind == 0 and (currentKind == 0 or currentKind == 1):
    return true
  if previousKind == 1 and currentKind == 0:
    return true
  return false

proc parseSequence(sentence: seq[Token], startPos: int): string =
  var pos = startPos
  var pieces = newSeq[Piece](0)
  while pos < sentence.len:
    var factor = 1
    var designator = -1
    var probePos = pos
    let probeValue = parseNumberWord(sentence, probePos)
    if probeValue > 1 and probePos < sentence.len and
       isPluralDesignator(sentence[probePos].text):
      factor = probeValue
      designator = designatorKind(sentence[probePos].text)
      pos = probePos + 1
    else:
      designator = designatorKind(sentence[pos].text)
      pos += 1
    var content = ""
    if designator == 0:
      content = $parseNumberWord(sentence, pos)
    elif designator == 1:
      if pos < sentence.len:
        content = sentence[pos].text
        pos += 1
    elif designator == 2:
      content = " "
    var pieceText = ""
    for repeatIndex in 0 ..< factor:
      if designator == 0 and repeatIndex > 0:
        pieceText.add ' '
      pieceText.add content
    pieces.add Piece(kind: designator, text: pieceText)
    if pos < sentence.len and sentence[pos].text == "followed":
      pos += 1
      if pos < sentence.len and sentence[pos].text == "by":
        pos += 1
    else:
      break
  var lineText = ""
  for index in 0 ..< pieces.len:
    if index > 0 and needsSpace(pieces[index - 1].kind, pieces[index].kind):
      lineText.add ' '
    lineText.add pieces[index].text
  return lineText

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for sentence in sentences:
  if sentence.len == 0:
    continue
  var pos = 0
  if sentence[pos].text == "the":
    pos += 1
  var lineCount = 1
  if pos < sentence.len and sentence[pos].text == "next":
    pos += 1
    if pos < sentence.len and sentence[pos].text == "line":
      pos += 1
    else:
      lineCount = parseNumberWord(sentence, pos)
      if pos < sentence.len:
        pos += 1
  elif pos < sentence.len and sentence[pos].text == "first":
    pos += 1
    if pos < sentence.len and sentence[pos].text == "line":
      pos += 1
  var isEmptyLine = false
  var lineText = ""
  if pos < sentence.len and (sentence[pos].text == "is" or sentence[pos].text == "are"):
    isEmptyLine = true
  elif pos < sentence.len and (sentence[pos].text == "contains" or
                               sentence[pos].text == "contain"):
    pos += 1
    lineText = parseSequence(sentence, pos)
  for lineIndex in 0 ..< lineCount:
    if not isEmptyLine:
      appendOutput(lineText)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

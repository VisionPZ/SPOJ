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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var allLines = newSeq[string]()
var lineStart = 0
for charIndex in 0 .. inputData.len - 1:
  if inputData[charIndex] == '\n':
    if charIndex > lineStart:
      allLines.add inputData[lineStart .. charIndex - 1]
    else:
      allLines.add ""
    lineStart = charIndex + 1

var lineIndex = 0

proc nextFilledLine(): string =
  while lineIndex < allLines.len:
    let candidate = allLines[lineIndex]
    lineIndex += 1
    var firstPos = 0
    while firstPos < candidate.len and candidate[firstPos] <= ' ':
      firstPos += 1
    if firstPos < candidate.len:
      return candidate
  return ""

while true:
  let scenarioLine = nextFilledLine()
  if scenarioLine.len == 0:
    break
  var countPos = 0
  let insignificantCount = nextInt(scenarioLine, countPos)
  if insignificantCount == 0:
    break
  var insignificantWords = newSeq[string](insignificantCount)
  for wordIndex in 0 .. insignificantCount - 1:
    let wordLine = nextFilledLine()
    var wordPos = 0
    insignificantWords[wordIndex] = nextWord(wordLine, wordPos)
  while true:
    let caseLine = nextFilledLine()
    if caseLine.len == 0:
      break
    var casePos = 0
    let firstToken = nextWord(caseLine, casePos)
    if firstToken == "LAST":
      break
    let abbreviation = firstToken
    var lowerAbbrev = ""
    for letterChar in abbreviation:
      if letterChar >= 'A' and letterChar <= 'Z':
        lowerAbbrev.add chr(int(letterChar) - 65 + 97)
      else:
        lowerAbbrev.add letterChar
    let abbrevLen = lowerAbbrev.len
    var significantWords = newSeq[string]()
    while true:
      let phraseWord = nextWord(caseLine, casePos)
      if phraseWord.len == 0:
        break
      var isInsignificant = false
      for ignoredWord in insignificantWords:
        if ignoredWord == phraseWord:
          isInsignificant = true
          break
      if not isInsignificant:
        significantWords.add phraseWord
    let wordCount = significantWords.len
    var wordWays = newSeq[seq[int64]]()
    for wordIndex in 0 .. wordCount - 1:
      let currentWord = significantWords[wordIndex]
      var localWays = newSeq[int64]((abbrevLen + 1) * (abbrevLen + 1))
      for startPos in 0 .. abbrevLen - 1:
        let rowBase = startPos * (abbrevLen + 1)
        localWays[rowBase] = 1
        for charIndex in 0 .. currentWord.len - 1:
          var matchCount = abbrevLen - startPos
          while matchCount >= 1:
            if lowerAbbrev[startPos + matchCount - 1] == currentWord[charIndex]:
              localWays[rowBase + matchCount] += localWays[rowBase + matchCount - 1]
            matchCount -= 1
      wordWays.add localWays
    var globalWays = newSeq[int64](abbrevLen + 1)
    globalWays[0] = 1
    for wordIndex in 0 .. wordCount - 1:
      var nextWays = newSeq[int64](abbrevLen + 1)
      for startPos in 0 .. abbrevLen - 1:
        if globalWays[startPos] == 0:
          continue
        let rowBase = startPos * (abbrevLen + 1)
        for matchCount in 1 .. abbrevLen - startPos:
          let localCount = wordWays[wordIndex][rowBase + matchCount]
          if localCount > 0:
            nextWays[startPos + matchCount] += globalWays[startPos] * localCount
      globalWays = nextWays
    let answerCount = globalWays[abbrevLen]
    appendOutput(abbreviation)
    if answerCount == 0:
      appendOutput(" is not a valid abbreviation\n")
    else:
      appendOutput(" can be formed in " & $answerCount & " ways\n")
stdout.write outputBuffer
outputBuffer.setLen 0

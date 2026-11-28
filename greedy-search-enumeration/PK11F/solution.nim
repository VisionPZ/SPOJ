const flushBlockBytes = 1 shl 17
const maximumCharacters = 160
const unreachableCost = 1000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextLine(data: string, pos: var int): string =
  var lineText = ""
  while pos < data.len and data[pos] != '\n':
    if data[pos] != '\r':
      lineText.add data[pos]
    pos += 1
  if pos < data.len:
    pos += 1
  return lineText

proc trimmed(text: string): string =
  var firstIndex = 0
  var lastIndex = text.len - 1
  while firstIndex <= lastIndex and text[firstIndex] <= ' ':
    firstIndex += 1
  while lastIndex >= firstIndex and text[lastIndex] <= ' ':
    lastIndex -= 1
  if firstIndex > lastIndex:
    return ""
  return text[firstIndex .. lastIndex]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var nearSubstitution: array[0..255, array[0..255, bool]]

var textLines = newSeq[string]()
while scanPos < inputData.len:
  textLines.add nextLine(inputData, scanPos)

var lineIndex = 0
while lineIndex < textLines.len and trimmed(textLines[lineIndex]) != "":
  let ruleText = trimmed(textLines[lineIndex])
  let ruleCharacter = int(ruleText[0])
  var fieldIndex = 1
  while fieldIndex < ruleText.len and ruleText[fieldIndex] <= ' ':
    fieldIndex += 1
  while fieldIndex < ruleText.len:
    let pairedCharacter = int(ruleText[fieldIndex])
    nearSubstitution[ruleCharacter][pairedCharacter] = true
    nearSubstitution[pairedCharacter][ruleCharacter] = true
    fieldIndex += 1
  lineIndex += 1

while lineIndex < textLines.len and trimmed(textLines[lineIndex]) == "":
  lineIndex += 1

var dictionaryWords = newSeq[string]()
var wordsByLength: array[0..maximumCharacters, seq[int]]
while lineIndex < textLines.len and trimmed(textLines[lineIndex]) != "":
  let wordText = trimmed(textLines[lineIndex])
  dictionaryWords.add wordText
  if wordText.len <= maximumCharacters:
    wordsByLength[wordText.len].add dictionaryWords.len - 1
  lineIndex += 1

while lineIndex < textLines.len and trimmed(textLines[lineIndex]) == "":
  lineIndex += 1

var queryWords = newSeq[string]()
while lineIndex < textLines.len:
  let wordText = trimmed(textLines[lineIndex])
  if wordText != "":
    queryWords.add wordText
  lineIndex += 1

proc substitutionCost(firstCharacter: char, secondCharacter: char): int =
  let firstCode = int(firstCharacter)
  let secondCode = int(secondCharacter)
  if firstCode == secondCode:
    return 0
  if nearSubstitution[firstCode][secondCode]:
    return 1
  return 2

proc editDistance(sourceWord: string, targetWord: string, cap: int): int =
  let sourceLength = sourceWord.len
  let targetLength = targetWord.len
  if 2 * abs(sourceLength - targetLength) > cap:
    return cap + 1
  let bandWidth = cap + 4
  var olderRow = newSeq[int](targetLength + 1)
  var previousRow = newSeq[int](targetLength + 1)
  var currentRow = newSeq[int](targetLength + 1)
  for columnIndex in 0 .. targetLength:
    if columnIndex <= bandWidth:
      previousRow[columnIndex] = 2 * columnIndex
    else:
      previousRow[columnIndex] = unreachableCost
  var sourceIndex = 1
  while sourceIndex <= sourceLength:
    var lowColumn = sourceIndex - bandWidth
    if lowColumn < 0:
      lowColumn = 0
    var highColumn = sourceIndex + bandWidth
    if highColumn > targetLength:
      highColumn = targetLength
    for columnIndex in 0 .. targetLength:
      currentRow[columnIndex] = unreachableCost
    if sourceIndex <= bandWidth:
      currentRow[0] = 2 * sourceIndex
    var rowMinimum = currentRow[0]
    var columnIndex = lowColumn
    if columnIndex == 0:
      columnIndex = 1
    while columnIndex <= highColumn:
      var bestValue = previousRow[columnIndex] + 2
      let insertValue = currentRow[columnIndex - 1] + 2
      if insertValue < bestValue:
        bestValue = insertValue
      let changeValue = previousRow[columnIndex - 1] +
                        substitutionCost(sourceWord[sourceIndex - 1], targetWord[columnIndex - 1])
      if changeValue < bestValue:
        bestValue = changeValue
      if sourceIndex >= 2 and columnIndex >= 2 and
         sourceWord[sourceIndex - 1] == targetWord[columnIndex - 2] and
         sourceWord[sourceIndex - 2] == targetWord[columnIndex - 1]:
        let swapValue = olderRow[columnIndex - 2] + 2
        if swapValue < bestValue:
          bestValue = swapValue
      currentRow[columnIndex] = bestValue
      if bestValue < rowMinimum:
        rowMinimum = bestValue
      columnIndex += 1
    if rowMinimum > cap:
      return cap + 1
    olderRow = previousRow
    previousRow = currentRow
    sourceIndex += 1
  if previousRow[targetLength] > cap:
    return cap + 1
  return previousRow[targetLength]

proc orderedLengths(queryLength: int): seq[int] =
  result = newSeq[int]()
  var shorter = queryLength
  var longer = queryLength + 1
  while shorter >= 0 or longer <= maximumCharacters:
    if shorter >= 0:
      result.add shorter
      shorter -= 1
    if longer <= maximumCharacters:
      result.add longer
      longer += 1

proc insertionSort(words: var seq[string]) =
  var wordIndex = 1
  while wordIndex < words.len:
    let wordValue = words[wordIndex]
    var previousIndex = wordIndex - 1
    while previousIndex >= 0 and words[previousIndex] > wordValue:
      words[previousIndex + 1] = words[previousIndex]
      previousIndex -= 1
    words[previousIndex + 1] = wordValue
    wordIndex += 1

for queryWord in queryWords:
  var bestDistance = unreachableCost
  var candidateLengths = orderedLengths(queryWord.len)
  for wordLength in candidateLengths:
    if 2 * abs(wordLength - queryWord.len) > bestDistance:
      break
    for wordIndex in wordsByLength[wordLength]:
      let candidateDistance = editDistance(queryWord, dictionaryWords[wordIndex], bestDistance)
      if candidateDistance < bestDistance:
        bestDistance = candidateDistance
  var bestMatches = newSeq[string]()
  for wordLength in candidateLengths:
    if 2 * abs(wordLength - queryWord.len) > bestDistance:
      break
    for wordIndex in wordsByLength[wordLength]:
      let candidateDistance = editDistance(queryWord, dictionaryWords[wordIndex], bestDistance)
      if candidateDistance == bestDistance:
        bestMatches.add dictionaryWords[wordIndex]
  insertionSort(bestMatches)
  appendOutput(queryWord & ":" & $bestDistance & ":")
  for matchIndex in 0 .. bestMatches.len - 1:
    if matchIndex > 0:
      appendOutput(" ")
    appendOutput(bestMatches[matchIndex])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const alphabetSize = 26

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < 'a' or data[pos] > 'z'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'a' and data[pos] <= 'z':
    word.add data[pos]
    pos += 1
  return word

proc hasNextWord(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < 'a' or data[cursor] > 'z'):
    cursor += 1
  return cursor < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasNextWord(inputData, scanPos):
  let text = nextWord(inputData, scanPos)
  let capacity = text.len * 2 + 2
  var linkState = newSeq[int](capacity)
  var longestLength = newSeq[int](capacity)
  var firstPosition = newSeq[int](capacity)
  var transition = newSeq[int](capacity * alphabetSize)
  for index in 0 .. capacity * alphabetSize - 1:
    transition[index] = -1
  linkState[0] = -1
  var stateCount = 1
  var lastState = 0
  for characterIndex in 0 .. text.len - 1:
    let letter = int(text[characterIndex]) - 97
    var currentState = stateCount
    stateCount += 1
    longestLength[currentState] = longestLength[lastState] + 1
    firstPosition[currentState] = characterIndex
    for letterIndex in 0 .. alphabetSize - 1:
      transition[currentState * alphabetSize + letterIndex] = -1
    var previousState = lastState
    while previousState != -1 and transition[previousState * alphabetSize + letter] == -1:
      transition[previousState * alphabetSize + letter] = currentState
      previousState = linkState[previousState]
    if previousState == -1:
      linkState[currentState] = 0
    else:
      let foundState = transition[previousState * alphabetSize + letter]
      if longestLength[previousState] + 1 == longestLength[foundState]:
        linkState[currentState] = foundState
      else:
        var cloneState = stateCount
        stateCount += 1
        longestLength[cloneState] = longestLength[previousState] + 1
        firstPosition[cloneState] = characterIndex
        linkState[cloneState] = linkState[foundState]
        for letterIndex in 0 .. alphabetSize - 1:
          transition[cloneState * alphabetSize + letterIndex] = transition[foundState * alphabetSize + letterIndex]
        while previousState != -1 and transition[previousState * alphabetSize + letter] == foundState:
          transition[previousState * alphabetSize + letter] = cloneState
          previousState = linkState[previousState]
        linkState[foundState] = cloneState
        linkState[currentState] = cloneState
    lastState = currentState
  var counts = newSeq[int64](alphabetSize)
  var prefixCount = newSeq[int](text.len + 1)
  for letter in 0 .. alphabetSize - 1:
    prefixCount[0] = 0
    for characterIndex in 0 .. text.len - 1:
      prefixCount[characterIndex + 1] = prefixCount[characterIndex]
      if int(text[characterIndex]) - 97 == letter:
        prefixCount[characterIndex + 1] = prefixCount[characterIndex + 1] + 1
    for stateIndex in 1 .. stateCount - 1:
      let startIndex = firstPosition[stateIndex] - longestLength[stateIndex] + 1
      let endIndex = firstPosition[stateIndex] - longestLength[linkState[stateIndex]]
      counts[letter] = counts[letter] + int64(prefixCount[endIndex + 1] - prefixCount[startIndex])
  for letter in 0 .. alphabetSize - 1:
    if letter > 0:
      outputBuffer.add ' '
    appendOutput($counts[letter])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const alphabetSize = 26

type SuffixState = object
  nextStates: array[0 .. alphabetSize - 1, int]
  suffixLink: int
  stateLength: int
  occurrences: int

proc resetState(state: var SuffixState) =
  for letterIndex in 0 .. alphabetSize - 1:
    state.nextStates[letterIndex] = -1
  state.suffixLink = -1
  state.stateLength = 0
  state.occurrences = 0

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
  while pos < data.len and (data[pos] < 'a' or data[pos] > 'z'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'a' and data[pos] <= 'z':
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let textLength = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
let sourceText = nextWord(inputData, scanPos)

var stateList = newSeq[SuffixState](2 * textLength + 2)
var stateCount = 1
var lastState = 0
resetState(stateList[0])

for charIndex in 0 .. textLength - 1:
  let letterIndex = int(sourceText[charIndex]) - 97
  let currentState = stateCount
  stateCount += 1
  resetState(stateList[currentState])
  stateList[currentState].stateLength = stateList[lastState].stateLength + 1
  stateList[currentState].occurrences = 1
  var walkState = lastState
  while walkState != -1 and stateList[walkState].nextStates[letterIndex] == -1:
    stateList[walkState].nextStates[letterIndex] = currentState
    walkState = stateList[walkState].suffixLink
  if walkState == -1:
    stateList[currentState].suffixLink = 0
  else:
    let nextState = stateList[walkState].nextStates[letterIndex]
    if stateList[walkState].stateLength + 1 == stateList[nextState].stateLength:
      stateList[currentState].suffixLink = nextState
    else:
      let cloneState = stateCount
      stateCount += 1
      stateList[cloneState] = stateList[nextState]
      stateList[cloneState].stateLength = stateList[walkState].stateLength + 1
      stateList[cloneState].occurrences = 0
      while walkState != -1 and stateList[walkState].nextStates[letterIndex] == nextState:
        stateList[walkState].nextStates[letterIndex] = cloneState
        walkState = stateList[walkState].suffixLink
      stateList[nextState].suffixLink = cloneState
      stateList[currentState].suffixLink = cloneState
  lastState = currentState

var countsByLength = newSeq[int](textLength + 1)
for stateIndex in 0 .. stateCount - 1:
  countsByLength[stateList[stateIndex].stateLength] += 1
var lengthTotal = 0
for lengthValue in 0 .. textLength:
  let previousCount = lengthTotal
  lengthTotal += countsByLength[lengthValue]
  countsByLength[lengthValue] = previousCount
var stateOrder = newSeq[int](stateCount)
for stateIndex in 0 .. stateCount - 1:
  let lengthValue = stateList[stateIndex].stateLength
  countsByLength[lengthValue] += 1
  stateOrder[countsByLength[lengthValue] - 1] = stateIndex
var orderIndex = stateCount - 1
while orderIndex >= 0:
  let stateIndex = stateOrder[orderIndex]
  let linkState = stateList[stateIndex].suffixLink
  if linkState != -1:
    stateList[linkState].occurrences += stateList[stateIndex].occurrences
  orderIndex -= 1

for queryIndex in 0 .. queryCount - 1:
  let queryWord = nextWord(inputData, scanPos)
  var activeState = 0
  var fullyMatched = true
  for charIndex in 0 .. queryWord.len - 1:
    let letterIndex = int(queryWord[charIndex]) - 97
    if letterIndex < 0 or letterIndex >= alphabetSize:
      fullyMatched = false
      break
    let nextState = stateList[activeState].nextStates[letterIndex]
    if nextState == -1:
      fullyMatched = false
      break
    activeState = nextState
  if fullyMatched:
    appendOutput($stateList[activeState].occurrences)
  else:
    appendOutput("0")
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0

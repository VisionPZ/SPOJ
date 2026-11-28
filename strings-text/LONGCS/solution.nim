const flushBlockBytes = 1 shl 17
const alphabetSize = 26

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

var suffixLink: seq[int] = @[]
var maxLength: seq[int] = @[]
var transitions: seq[seq[int]] = @[]
var lastState = 0

proc newAutomatonState(lengthValue: int): int =
  let stateIndex = suffixLink.len
  suffixLink.add -1
  maxLength.add lengthValue
  var row = newSeq[int](alphabetSize)
  for letterIndex in 0 .. alphabetSize - 1:
    row[letterIndex] = -1
  transitions.add row
  return stateIndex

proc extendAutomaton(letterIndex: int) =
  let currentState = newAutomatonState(maxLength[lastState] + 1)
  var walkState = lastState
  while walkState != -1 and transitions[walkState][letterIndex] == -1:
    transitions[walkState][letterIndex] = currentState
    walkState = suffixLink[walkState]
  if walkState == -1:
    suffixLink[currentState] = 0
  else:
    let nextState = transitions[walkState][letterIndex]
    if maxLength[walkState] + 1 == maxLength[nextState]:
      suffixLink[currentState] = nextState
    else:
      let cloneState = newAutomatonState(maxLength[walkState] + 1)
      for index in 0 .. alphabetSize - 1:
        transitions[cloneState][index] = transitions[nextState][index]
      suffixLink[cloneState] = suffixLink[nextState]
      while walkState != -1 and transitions[walkState][letterIndex] == nextState:
        transitions[walkState][letterIndex] = cloneState
        walkState = suffixLink[walkState]
      suffixLink[nextState] = cloneState
      suffixLink[currentState] = cloneState
  lastState = currentState

let caseCount = nextInt(inputData, scanPos)
for caseNumber in 0 .. caseCount - 1:
  let stringCount = nextInt(inputData, scanPos)
  let firstString = nextWord(inputData, scanPos)
  suffixLink.setLen 0
  maxLength.setLen 0
  transitions.setLen 0
  discard newAutomatonState(0)
  lastState = 0
  for position in 0 .. firstString.len - 1:
    extendAutomaton(int(firstString[position]) - 97)
  let stateCount = suffixLink.len
  var commonLengths = newSeq[int](stateCount)
  var matchLengths = newSeq[int](stateCount)
  var order = newSeq[int](stateCount)
  var buckets = newSeq[int](firstString.len + 1)
  for stateIndex in 0 .. stateCount - 1:
    commonLengths[stateIndex] = maxLength[stateIndex]
    buckets[maxLength[stateIndex]] += 1
    matchLengths[stateIndex] = 0
  for lengthValue in 1 .. firstString.len:
    buckets[lengthValue] += buckets[lengthValue - 1]
  for stateIndex in countdown(stateCount - 1, 0):
    buckets[maxLength[stateIndex]] -= 1
    order[buckets[maxLength[stateIndex]]] = stateIndex
  for stringIndex in 1 .. stringCount - 1:
    let sampleString = nextWord(inputData, scanPos)
    for stateIndex in 0 .. stateCount - 1:
      matchLengths[stateIndex] = 0
    var walkState = 0
    var walkLength = 0
    for position in 0 .. sampleString.len - 1:
      let letterIndex = int(sampleString[position]) - 97
      if transitions[walkState][letterIndex] != -1:
        walkState = transitions[walkState][letterIndex]
        walkLength += 1
      else:
        while walkState != -1 and transitions[walkState][letterIndex] == -1:
          walkState = suffixLink[walkState]
        if walkState == -1:
          walkState = 0
          walkLength = 0
        else:
          walkLength = maxLength[walkState] + 1
          walkState = transitions[walkState][letterIndex]
      if walkLength > matchLengths[walkState]:
        matchLengths[walkState] = walkLength
    for orderIndex in countdown(stateCount - 1, 1):
      let stateIndex = order[orderIndex]
      let parentState = suffixLink[stateIndex]
      if parentState >= 0:
        let carried = min(matchLengths[stateIndex], maxLength[parentState])
        if carried > matchLengths[parentState]:
          matchLengths[parentState] = carried
    for stateIndex in 0 .. stateCount - 1:
      if matchLengths[stateIndex] < commonLengths[stateIndex]:
        commonLengths[stateIndex] = matchLengths[stateIndex]
  var bestLength = 0
  for stateIndex in 1 .. stateCount - 1:
    let minimumLength = maxLength[suffixLink[stateIndex]] + 1
    if commonLengths[stateIndex] >= minimumLength and commonLengths[stateIndex] > bestLength:
      bestLength = commonLengths[stateIndex]
  appendOutput($bestLength)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

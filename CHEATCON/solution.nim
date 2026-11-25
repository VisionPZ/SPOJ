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

proc splitInputLines(data: string): seq[string] =
  var lines: seq[string] = @[]
  var lineStart = 0
  for index in 0 .. data.len - 1:
    if data[index] == '\n':
      if index > lineStart:
        lines.add data[lineStart .. index - 1]
      else:
        lines.add ""
      lineStart = index + 1
  return lines

type Fragment = tuple[start: int, finish: int]

var epsilonEdges: seq[seq[int]] = @[]
var charEdges: seq[seq[tuple[letter: char, target: int]]] = @[]

proc newState(): int =
  let stateIndex = epsilonEdges.len
  epsilonEdges.add @[]
  charEdges.add @[]
  return stateIndex

proc makeAtom(letter: char): Fragment =
  let startState = newState()
  let finishState = newState()
  charEdges[startState].add (letter, finishState)
  return (startState, finishState)

proc makeConcat(firstPart: Fragment, secondPart: Fragment): Fragment =
  epsilonEdges[firstPart.finish].add secondPart.start
  return (firstPart.start, secondPart.finish)

proc makeUnion(firstPart: Fragment, secondPart: Fragment): Fragment =
  let startState = newState()
  let finishState = newState()
  epsilonEdges[startState].add firstPart.start
  epsilonEdges[startState].add secondPart.start
  epsilonEdges[firstPart.finish].add finishState
  epsilonEdges[secondPart.finish].add finishState
  return (startState, finishState)

proc makeStar(innerPart: Fragment): Fragment =
  let startState = newState()
  let finishState = newState()
  epsilonEdges[startState].add innerPart.start
  epsilonEdges[startState].add finishState
  epsilonEdges[innerPart.finish].add innerPart.start
  epsilonEdges[innerPart.finish].add finishState
  return (startState, finishState)

proc parsePattern(pattern: string, pos: var int): Fragment =
  if pos >= pattern.len:
    return makeAtom('a')
  if pattern[pos] != '(':
    let letter = pattern[pos]
    pos += 1
    return makeAtom(letter)
  pos += 1
  let firstPart = parsePattern(pattern, pos)
  if pos >= pattern.len:
    return firstPart
  if pattern[pos] == ')':
    pos += 1
    return firstPart
  let operation = pattern[pos]
  pos += 1
  if operation == '*':
    while pos < pattern.len and pattern[pos] != ')':
      pos += 1
    if pos < pattern.len:
      pos += 1
    return makeStar(firstPart)
  let secondPart = parsePattern(pattern, pos)
  if pos < pattern.len:
    pos += 1
  if operation == '.':
    return makeConcat(firstPart, secondPart)
  return makeUnion(firstPart, secondPart)

proc epsilonClosure(seed: seq[bool]): seq[bool] =
  var reached = seed
  var pending: seq[int] = @[]
  for stateIndex in 0 .. reached.len - 1:
    if reached[stateIndex]:
      pending.add stateIndex
  while pending.len > 0:
    let stateIndex = pending[pending.len - 1]
    pending.setLen pending.len - 1
    for targetState in epsilonEdges[stateIndex]:
      if not reached[targetState]:
        reached[targetState] = true
        pending.add targetState
  return reached

proc acceptsWord(startState: int, finishState: int, word: string): bool =
  let stateCount = epsilonEdges.len
  var active = newSeq[bool](stateCount)
  active[startState] = true
  active = epsilonClosure(active)
  for letter in word:
    var moved = newSeq[bool](stateCount)
    for stateIndex in 0 .. stateCount - 1:
      if active[stateIndex]:
        for edge in charEdges[stateIndex]:
          if edge.letter == letter:
            moved[edge.target] = true
    active = epsilonClosure(moved)
  return active[finishState]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let inputLines = splitInputLines(inputData)
var linePos = 0
while linePos < inputLines.len:
  while linePos < inputLines.len and inputLines[linePos].len == 0:
    linePos += 1
  if linePos >= inputLines.len:
    break
  let pattern = inputLines[linePos]
  linePos += 1
  while linePos < inputLines.len and inputLines[linePos].len == 0:
    linePos += 1
  if linePos >= inputLines.len:
    break
  scanPos = 0
  let queryCount = nextInt(inputLines[linePos], scanPos)
  linePos += 1
  epsilonEdges.setLen 0
  charEdges.setLen 0
  var patternPos = 0
  let automaton = parsePattern(pattern, patternPos)
  for queryIndex in 0 .. queryCount - 1:
    var word = ""
    if linePos < inputLines.len:
      word = inputLines[linePos]
      linePos += 1
    if acceptsWord(automaton.start, automaton.finish, word):
      appendOutput("Y")
    else:
      appendOutput("N")
    outputBuffer.add '\n'
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

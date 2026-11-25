import strutils

const flushBlockBytes = 1 shl 17
const alphabetSize = 62

type TrieNode = object
  next: array[alphabetSize, int]
  failure: int
  terminal: bool

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let tokenStart = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[tokenStart .. pos - 1]

proc tokenInteger(token: string): int =
  var value = 0
  for character in token:
    value = value * 10 + int(character) - 48
  return value

proc tokenProbability(token: string): float64 =
  var wholePart = 0.0
  var fractionPart = 0.0
  var scaleValue = 1.0
  var afterPoint = false
  for character in token:
    if character == '.':
      afterPoint = true
    elif afterPoint:
      fractionPart = fractionPart * 10.0 + float64(int(character) - 48)
      scaleValue = scaleValue * 10.0
    else:
      wholePart = wholePart * 10.0 + float64(int(character) - 48)
  return wholePart + fractionPart / scaleValue

proc characterIndex(character: char): int =
  if character >= 'a' and character <= 'z':
    return int(character) - 97
  if character >= 'A' and character <= 'Z':
    return int(character) - 65 + 26
  return int(character) - 48 + 52

proc makeNode(): TrieNode =
  for letterIndex in 0 .. alphabetSize - 1:
    result.next[letterIndex] = -1
  result.failure = 0
  result.terminal = false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = tokenInteger(nextToken(inputData, scanPos))
for caseNumber in 1 .. caseCount:
  let patternCount = tokenInteger(nextToken(inputData, scanPos))
  var nodes = newSeq[TrieNode](1)
  nodes[0] = makeNode()
  nodes[0].failure = -1
  for patternIndex in 0 .. patternCount - 1:
    let pattern = nextToken(inputData, scanPos)
    var state = 0
    for character in pattern:
      let letterIndex = characterIndex(character)
      if nodes[state].next[letterIndex] == -1:
        nodes.add makeNode()
        nodes[state].next[letterIndex] = nodes.len - 1
      state = nodes[state].next[letterIndex]
    nodes[state].terminal = true

  let characterCount = tokenInteger(nextToken(inputData, scanPos))
  var letterProbability = newSeq[float64](alphabetSize)
  var validLetters = newSeq[int](0)
  for characterIndexValue in 0 .. characterCount - 1:
    let symbolToken = nextToken(inputData, scanPos)
    let probabilityToken = nextToken(inputData, scanPos)
    let letterIndex = characterIndex(symbolToken[0])
    letterProbability[letterIndex] = tokenProbability(probabilityToken)
    validLetters.add letterIndex

  let generatedLength = tokenInteger(nextToken(inputData, scanPos))

  var queue = newSeq[int](nodes.len)
  var queueHead = 0
  var queueTail = 0
  for letterIndex in 0 .. alphabetSize - 1:
    let child = nodes[0].next[letterIndex]
    if child != -1:
      nodes[child].failure = 0
      queue[queueTail] = child
      queueTail += 1
  while queueHead < queueTail:
    let currentNode = queue[queueHead]
    queueHead += 1
    for letterIndex in 0 .. alphabetSize - 1:
      let child = nodes[currentNode].next[letterIndex]
      if child == -1:
        continue
      var fallback = nodes[currentNode].failure
      while fallback != -1 and nodes[fallback].next[letterIndex] == -1:
        fallback = nodes[fallback].failure
      if fallback == -1:
        nodes[child].failure = 0
      else:
        nodes[child].failure = nodes[fallback].next[letterIndex]
      queue[queueTail] = child
      queueTail += 1

  var hasMatch = newSeq[bool](nodes.len)
  for state in 0 .. nodes.len - 1:
    hasMatch[state] = nodes[state].terminal or (state != 0 and hasMatch[nodes[state].failure])

  var transition = newSeq[array[alphabetSize, int]](nodes.len)
  for state in 0 .. nodes.len - 1:
    for letterIndex in 0 .. alphabetSize - 1:
      var currentNode = state
      while currentNode != -1 and nodes[currentNode].next[letterIndex] == -1:
        currentNode = nodes[currentNode].failure
      if currentNode == -1:
        transition[state][letterIndex] = 0
      else:
        transition[state][letterIndex] = nodes[currentNode].next[letterIndex]

  var probabilities = newSeq[float64](nodes.len)
  var nextProbabilities = newSeq[float64](nodes.len)
  probabilities[0] = 1.0
  for stepIndex in 0 .. generatedLength - 1:
    for state in 0 .. nodes.len - 1:
      nextProbabilities[state] = 0.0
    for state in 0 .. nodes.len - 1:
      let stateProbability = probabilities[state]
      if stateProbability == 0.0:
        continue
      for letterIndex in validLetters:
        let nextState = transition[state][letterIndex]
        if not hasMatch[nextState]:
          nextProbabilities[nextState] += stateProbability * letterProbability[letterIndex]
    swap probabilities, nextProbabilities

  var noMatchProbability = 0.0
  for state in 0 .. nodes.len - 1:
    if not hasMatch[state]:
      noMatchProbability += probabilities[state]
  appendOutput("Case #" & $caseNumber & ": " & formatFloat(noMatchProbability, ffDecimal, 6))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

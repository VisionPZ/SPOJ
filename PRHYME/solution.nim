const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var wordStarts = newSeq[int]()
var wordLengths = newSeq[int]()
var queryStarts = newSeq[int]()
var queryLengths = newSeq[int]()
var readingQueries = false
var lineStart = 0
for charIndex in 0 .. inputData.len - 1:
  if inputData[charIndex] == '\n':
    let lineLength = charIndex - lineStart
    if lineLength == 0:
      readingQueries = true
    elif readingQueries:
      queryStarts.add lineStart
      queryLengths.add lineLength
    else:
      wordStarts.add lineStart
      wordLengths.add lineLength
    lineStart = charIndex + 1

proc compareWords(firstStart: int, firstLength: int, secondStart: int, secondLength: int): int =
  let commonLength = min(firstLength, secondLength)
  for offset in 0 .. commonLength - 1:
    let firstChar = inputData[firstStart + offset]
    let secondChar = inputData[secondStart + offset]
    if firstChar < secondChar:
      return -1
    if firstChar > secondChar:
      return 1
  if firstLength < secondLength:
    return -1
  if firstLength > secondLength:
    return 1
  return 0

proc sameAsQuery(queryStart: int, queryLength: int, wordIndex: int): bool =
  let wordLength = wordLengths[wordIndex]
  if wordLength != queryLength:
    return false
  for offset in 0 .. wordLength - 1:
    if inputData[wordStarts[wordIndex] + offset] != inputData[queryStart + offset]:
      return false
  return true

proc considerCandidate(candidate: int32, bestValue: var int32, secondValue: var int32) =
  if candidate < 0:
    return
  if bestValue < 0 or compareWords(wordStarts[int(bestValue)], wordLengths[int(bestValue)],
                                   wordStarts[int(candidate)], wordLengths[int(candidate)]) > 0:
    if bestValue != candidate:
      secondValue = bestValue
      bestValue = candidate
  elif candidate != bestValue and (secondValue < 0 or
       compareWords(wordStarts[int(secondValue)], wordLengths[int(secondValue)],
                    wordStarts[int(candidate)], wordLengths[int(candidate)]) > 0):
    secondValue = candidate

var nodeHeads = newSeq[int32]()
var nodeWords = newSeq[int32]()
var nodeBests = newSeq[int32]()
var nodeSeconds = newSeq[int32]()
var edgeLetters = newSeq[int32]()
var edgeChildren = newSeq[int32]()
var edgeNexts = newSeq[int32]()
nodeHeads.add 0
nodeWords.add -1
nodeBests.add -1
nodeSeconds.add -1

for wordIndex in 0 .. wordStarts.len - 1:
  var currentNode = 0
  let wordStart = wordStarts[wordIndex]
  let wordLength = wordLengths[wordIndex]
  var reverseOffset = wordLength - 1
  while reverseOffset >= 0:
    let letterValue = int32(int(inputData[wordStart + reverseOffset]) - 96)
    var edgeIndex = nodeHeads[currentNode]
    var matchedEdge: int32 = 0
    while edgeIndex != 0:
      if edgeLetters[int(edgeIndex) - 1] == letterValue:
        matchedEdge = edgeIndex
        break
      edgeIndex = edgeNexts[int(edgeIndex) - 1]
    if matchedEdge == 0:
      let newNodeIndex = nodeHeads.len
      nodeHeads.add 0
      nodeWords.add -1
      nodeBests.add -1
      nodeSeconds.add -1
      let newEdgeIndex = edgeLetters.len + 1
      edgeLetters.add letterValue
      edgeChildren.add int32(newNodeIndex)
      edgeNexts.add nodeHeads[currentNode]
      nodeHeads[currentNode] = int32(newEdgeIndex)
      matchedEdge = int32(newEdgeIndex)
    currentNode = int(edgeChildren[int(matchedEdge) - 1])
    reverseOffset -= 1
  nodeWords[currentNode] = int32(wordIndex)

for nodeIndex in countdown(nodeHeads.len - 1, 0):
  var bestValue = nodeWords[nodeIndex]
  var secondValue: int32 = -1
  var edgeIndex = nodeHeads[nodeIndex]
  while edgeIndex != 0:
    let childNode = int(edgeChildren[int(edgeIndex) - 1])
    considerCandidate(nodeBests[childNode], bestValue, secondValue)
    considerCandidate(nodeSeconds[childNode], bestValue, secondValue)
    edgeIndex = edgeNexts[int(edgeIndex) - 1]
  nodeBests[nodeIndex] = bestValue
  nodeSeconds[nodeIndex] = secondValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for queryIndex in 0 .. queryStarts.len - 1:
  let queryStart = queryStarts[queryIndex]
  let queryLength = queryLengths[queryIndex]
  var answerWord: int32 = -1
  var currentNode = 0
  var matchedDepth = 0
  while true:
    var candidate: int32 = -1
    let bestValue = nodeBests[currentNode]
    let secondValue = nodeSeconds[currentNode]
    if bestValue >= 0 and not sameAsQuery(queryStart, queryLength, int(bestValue)):
      candidate = bestValue
    elif secondValue >= 0 and not sameAsQuery(queryStart, queryLength, int(secondValue)):
      candidate = secondValue
    if candidate >= 0:
      answerWord = candidate
    if matchedDepth >= queryLength:
      break
    let letterValue = int32(int(inputData[queryStart + queryLength - 1 - matchedDepth]) - 96)
    var edgeIndex = nodeHeads[currentNode]
    var matchedEdge: int32 = 0
    while edgeIndex != 0:
      if edgeLetters[int(edgeIndex) - 1] == letterValue:
        matchedEdge = edgeIndex
        break
      edgeIndex = edgeNexts[int(edgeIndex) - 1]
    if matchedEdge == 0:
      break
    currentNode = int(edgeChildren[int(matchedEdge) - 1])
    matchedDepth += 1
  if answerWord < 0:
    answerWord = nodeBests[0]
  let answerStart = wordStarts[int(answerWord)]
  let answerLength = wordLengths[int(answerWord)]
  var answerText = ""
  for offset in 0 .. answerLength - 1:
    answerText.add inputData[answerStart + offset]
  appendOutput(answerText)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

const flushBlockBytes = 1 shl 17
const buttonLetters = 3
const firstLetter = 65
const impossibleScore = -1000000000

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
  while pos < data.len and (data[pos] < 'A' or data[pos] > 'C'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'A' and data[pos] <= 'C':
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let comboCount = nextInt(inputData, scanPos)
let pressCount = nextInt(inputData, scanPos)
var transitionTable = newSeq[int](buttonLetters)
for letterIndex in 0 .. buttonLetters - 1:
  transitionTable[letterIndex] = -1
var failureLinks = newSeq[int](1)
var nodeScores = newSeq[int](1)
var nodeCount = 1
for comboIndex in 0 .. comboCount - 1:
  let comboWord = nextWord(inputData, scanPos)
  var currentNode = 0
  for letterIndex in 0 .. comboWord.len - 1:
    let letterValue = int(comboWord[letterIndex]) - firstLetter
    var targetNode = transitionTable[currentNode * buttonLetters + letterValue]
    if targetNode < 0:
      targetNode = nodeCount
      nodeCount += 1
      for addedLetter in 0 .. buttonLetters - 1:
        transitionTable.add -1
      failureLinks.add 0
      nodeScores.add 0
      transitionTable[currentNode * buttonLetters + letterValue] = targetNode
    currentNode = targetNode
  nodeScores[currentNode] += 1
var traversalQueue = newSeq[int](nodeCount)
var queueHead = 0
var queueTail = 0
for letterIndex in 0 .. buttonLetters - 1:
  let childNode = transitionTable[letterIndex]
  if childNode < 0:
    transitionTable[letterIndex] = 0
  else:
    failureLinks[childNode] = 0
    traversalQueue[queueTail] = childNode
    queueTail += 1
while queueHead < queueTail:
  let currentNode = traversalQueue[queueHead]
  queueHead += 1
  nodeScores[currentNode] += nodeScores[failureLinks[currentNode]]
  for letterIndex in 0 .. buttonLetters - 1:
    let childNode = transitionTable[currentNode * buttonLetters + letterIndex]
    if childNode < 0:
      transitionTable[currentNode * buttonLetters + letterIndex] = transitionTable[failureLinks[currentNode] * buttonLetters + letterIndex]
    else:
      failureLinks[childNode] = transitionTable[failureLinks[currentNode] * buttonLetters + letterIndex]
      traversalQueue[queueTail] = childNode
      queueTail += 1
var currentScores = newSeq[int](nodeCount)
var nextScores = newSeq[int](nodeCount)
for nodeIndex in 0 .. nodeCount - 1:
  currentScores[nodeIndex] = impossibleScore
currentScores[0] = 0
for pressIndex in 0 .. pressCount - 1:
  for nodeIndex in 0 .. nodeCount - 1:
    nextScores[nodeIndex] = impossibleScore
  for stateIndex in 0 .. nodeCount - 1:
    let baseScore = currentScores[stateIndex]
    if baseScore <= impossibleScore div 2:
      continue
    for letterIndex in 0 .. buttonLetters - 1:
      let targetNode = transitionTable[stateIndex * buttonLetters + letterIndex]
      let candidateScore = baseScore + nodeScores[targetNode]
      if candidateScore > nextScores[targetNode]:
        nextScores[targetNode] = candidateScore
  swap currentScores, nextScores
var bestScore = 0
for nodeIndex in 0 .. nodeCount - 1:
  if currentScores[nodeIndex] > bestScore:
    bestScore = currentScores[nodeIndex]
appendOutput($bestScore)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

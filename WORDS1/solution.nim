const flushBlockBytes = 1 shl 18
const digitBase = 48
const letterBase = 97
const letterCount = 26
const possibleMessage = "Ordering is possible.\n"
const impossibleMessage = "The door cannot be opened.\n"

proc skipWhitespace(data: string, scanPos: var int) =
  while scanPos < data.len and data[scanPos] <= ' ':
    scanPos += 1

proc nextInt(data: string, scanPos: var int): int =
  skipWhitespace(data, scanPos)
  result = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    result = result * 10 + (int(data[scanPos]) - digitBase)
    scanPos += 1

proc nextWordEnds(data: string, scanPos: var int): tuple[first: char, last: char] =
  skipWhitespace(data, scanPos)
  let wordStart = scanPos
  while scanPos < data.len and data[scanPos] > ' ':
    scanPos += 1
  result.first = data[wordStart]
  result.last = data[scanPos - 1]

proc findRoot(parent: var array[letterCount, int], node: int): int =
  var current = node
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  result = current

proc unionLetters(parent: var array[letterCount, int], left: int, right: int) =
  let leftRoot = findRoot(parent, left)
  let rightRoot = findRoot(parent, right)
  if leftRoot != rightRoot:
    parent[leftRoot] = rightRoot

var inputData = ""
var currentLine = ""
while readLine(stdin, currentLine):
  inputData.add currentLine
  inputData.add '\n'

var scanPos = 0
let testCount = nextInt(inputData, scanPos)
var outputBuffer = ""

var parent: array[letterCount, int]
var outDegree: array[letterCount, int]
var inDegree: array[letterCount, int]

for caseIndex in 0 ..< testCount:
  for letter in 0 ..< letterCount:
    parent[letter] = letter
    outDegree[letter] = 0
    inDegree[letter] = 0

  let wordCount = nextInt(inputData, scanPos)
  var referenceVertex = -1
  for wordIndex in 0 ..< wordCount:
    let wordEnds = nextWordEnds(inputData, scanPos)
    let firstLetter = int(wordEnds.first) - letterBase
    let lastLetter = int(wordEnds.last) - letterBase
    outDegree[firstLetter] += 1
    inDegree[lastLetter] += 1
    unionLetters(parent, firstLetter, lastLetter)
    if referenceVertex < 0:
      referenceVertex = firstLetter

  var orderingPossible = true
  if wordCount > 0:
    for letter in 0 ..< letterCount:
      if inDegree[letter] + outDegree[letter] > 0:
        if findRoot(parent, letter) != findRoot(parent, referenceVertex):
          orderingPossible = false

    if orderingPossible:
      var startSurplusCount = 0
      var endSurplusCount = 0
      for letter in 0 ..< letterCount:
        let difference = outDegree[letter] - inDegree[letter]
        if difference == 1:
          startSurplusCount += 1
        elif difference == -1:
          endSurplusCount += 1
        elif difference != 0:
          orderingPossible = false
      if not ((startSurplusCount == 1 and endSurplusCount == 1) or
              (startSurplusCount == 0 and endSurplusCount == 0)):
        orderingPossible = false

  if orderingPossible:
    outputBuffer.add possibleMessage
  else:
    outputBuffer.add impossibleMessage
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer

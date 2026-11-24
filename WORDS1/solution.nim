const flushBlockBytes = 1 shl 18
const digitBase = 48
const letterBase = 97
const letterCount = 26
const possibleMessage = "Ordering is possible.\n"
const impossibleMessage = "The door cannot be opened.\n"

proc skipWhitespace(data: string, i: var int) =
  while i < data.len and data[i] <= ' ':
    i += 1

proc nextInt(data: string, i: var int): int =
  skipWhitespace(data, i)
  result = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    result = result * 10 + (int(data[i]) - digitBase)
    i += 1

proc nextWordEnds(data: string, i: var int): tuple[first: char, last: char] =
  skipWhitespace(data, i)
  let j = i
  while i < data.len and data[i] > ' ':
    i += 1
  result.first = data[j]
  result.last = data[i - 1]

proc findRoot(parent: var array[letterCount, int], i: int): int =
  var j = i
  while parent[j] != j:
    parent[j] = parent[parent[j]]
    j = parent[j]
  result = j

proc unionLetters(parent: var array[letterCount, int], i: int, j: int) =
  let leftRoot = findRoot(parent, i)
  let rightRoot = findRoot(parent, j)
  if leftRoot != rightRoot:
    parent[leftRoot] = rightRoot

var inputData = ""
var currentLine = ""
while readLine(stdin, currentLine):
  inputData.add currentLine
  inputData.add '\n'

var i = 0
let testCount = nextInt(inputData, i)
var outputBuffer = ""

var parent: array[letterCount, int]
var outDegree: array[letterCount, int]
var inDegree: array[letterCount, int]

for j in 0 ..< testCount:
  for k in 0 ..< letterCount:
    parent[k] = k
    outDegree[k] = 0
    inDegree[k] = 0

  let wordCount = nextInt(inputData, i)
  var referenceVertex = -1
  for l in 0 ..< wordCount:
    let wordEnds = nextWordEnds(inputData, i)
    let firstLetter = int(wordEnds.first) - letterBase
    let lastLetter = int(wordEnds.last) - letterBase
    outDegree[firstLetter] += 1
    inDegree[lastLetter] += 1
    unionLetters(parent, firstLetter, lastLetter)
    if referenceVertex < 0:
      referenceVertex = firstLetter

  var orderingPossible = true
  if wordCount > 0:
    for k in 0 ..< letterCount:
      if inDegree[k] + outDegree[k] > 0:
        if findRoot(parent, k) != findRoot(parent, referenceVertex):
          orderingPossible = false

    if orderingPossible:
      var startSurplusCount = 0
      var endSurplusCount = 0
      for k in 0 ..< letterCount:
        let difference = outDegree[k] - inDegree[k]
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

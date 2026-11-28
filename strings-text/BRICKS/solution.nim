const
  flushBlockBytes = 1 shl 18
  letterKinds = 26
  firstLetterCode = 97
  firstDigitCode = 48
  moduloBase = 4294967296'i64

var inputData = ""
var lineBuffer = ""
while readLine(stdin, lineBuffer):
  inputData.add(lineBuffer)
  inputData.add('\n')

var i = 0

proc skipWhitespace(data: string, i: var int) =
  while i < data.len and data[i] <= ' ':
    inc i

proc nextInt(data: string, i: var int): int =
  skipWhitespace(data, i)
  result = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    result = result * 10 + (int(data[i]) - firstDigitCode)
    inc i

proc readWord(data: string, i: var int): tuple[start: int, length: int] =
  skipWhitespace(data, i)
  result.start = i
  while i < data.len and data[i] >= 'a' and data[i] <= 'z':
    inc i
  result.length = i - result.start

proc bitAdd(tree: var seq[int], i: int) =
  var j = i
  while j < tree.len:
    tree[j] += 1
    j += j and (-j)

proc bitSum(tree: var seq[int], i: int): int =
  var j = i
  result = 0
  while j > 0:
    result += tree[j]
    j -= j and (-j)

var outputBuffer = ""

proc flushOutput() =
  stdout.write(outputBuffer)
  outputBuffer.setLen(0)

proc appendAnswer(answer: int64) =
  outputBuffer.add($answer)
  outputBuffer.add('\n')
  if outputBuffer.len >= flushBlockBytes:
    flushOutput()

let caseCount = nextInt(inputData, i)
for j in 0 .. caseCount - 1:
  let sourceWord = readWord(inputData, i)
  let targetWord = readWord(inputData, i)
  let pairCount = nextInt(inputData, i)

  var adjacencyMask: array[letterKinds, int]
  for k in 0 .. pairCount - 1:
    skipWhitespace(inputData, i)
    let leftLetter = int(inputData[i]) - firstLetterCode
    inc i
    skipWhitespace(inputData, i)
    let rightLetter = int(inputData[i]) - firstLetterCode
    inc i
    adjacencyMask[leftLetter] = adjacencyMask[leftLetter] or (1 shl rightLetter)
    adjacencyMask[rightLetter] = adjacencyMask[rightLetter] or (1 shl leftLetter)

  var possible = true
  var sourceFreq: array[letterKinds, int]
  var targetFreq: array[letterKinds, int]
  for k in 0 .. sourceWord.length - 1:
    inc sourceFreq[int(inputData[sourceWord.start + k]) - firstLetterCode]
  for k in 0 .. targetWord.length - 1:
    inc targetFreq[int(inputData[targetWord.start + k]) - firstLetterCode]
  for k in 0 .. letterKinds - 1:
    if sourceFreq[k] != targetFreq[k]:
      possible = false

  var answer: int64 = 0
  if possible and sourceWord.length > 0:
    var positionLists: array[letterKinds, seq[int]]
    for k in 0 .. letterKinds - 1:
      positionLists[k] = newSeq[int](targetFreq[k])
    var filled: array[letterKinds, int]
    for k in 0 .. targetWord.length - 1:
      let l = int(inputData[targetWord.start + k]) - firstLetterCode
      positionLists[l][filled[l]] = k
      inc filled[l]

    var targetIndexAt = newSeq[int](sourceWord.length)
    for k in 0 .. letterKinds - 1:
      filled[k] = 0
    for k in 0 .. sourceWord.length - 1:
      let l = int(inputData[sourceWord.start + k]) - firstLetterCode
      targetIndexAt[k] = positionLists[l][filled[l]]
      inc filled[l]

    var connectedNeighbours: array[letterKinds, seq[int]]
    for k in 0 .. letterKinds - 1:
      connectedNeighbours[k] = newSeq[int]()
      for l in 0 .. letterKinds - 1:
        if (adjacencyMask[k] and (1 shl l)) != 0:
          connectedNeighbours[k].add(l)

    var totalTree = newSeq[int](sourceWord.length + 1)
    var letterTrees: array[letterKinds, seq[int]]
    var letterTotals: array[letterKinds, int]
    for k in 0 .. letterKinds - 1:
      letterTrees[k] = newSeq[int](sourceWord.length + 1)

    for k in 0 .. sourceWord.length - 1:
      let l = int(inputData[sourceWord.start + k]) - firstLetterCode
      let i = targetIndexAt[k] + 1
      let allInversions = k - bitSum(totalTree, i)
      var connectedInversions = 0
      for j in connectedNeighbours[l]:
        connectedInversions += letterTotals[j] - bitSum(letterTrees[j], i)
      if connectedInversions != allInversions:
        possible = false
        break
      answer += int64(connectedInversions)
      bitAdd(totalTree, i)
      bitAdd(letterTrees[l], i)
      inc letterTotals[l]

  if not possible:
    outputBuffer.add("-1\n")
  else:
    appendAnswer(answer mod moduloBase)

flushOutput()

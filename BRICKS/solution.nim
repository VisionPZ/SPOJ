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

var scanPos = 0

proc skipWhitespace(data: string, pos: var int) =
  while pos < data.len and data[pos] <= ' ':
    inc pos

proc nextInt(data: string, pos: var int): int =
  skipWhitespace(data, pos)
  result = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    result = result * 10 + (int(data[pos]) - firstDigitCode)
    inc pos

proc readWord(data: string, pos: var int): tuple[start: int, length: int] =
  skipWhitespace(data, pos)
  result.start = pos
  while pos < data.len and data[pos] >= 'a' and data[pos] <= 'z':
    inc pos
  result.length = pos - result.start

proc bitAdd(tree: var seq[int], index: int) =
  var idx = index
  while idx < tree.len:
    tree[idx] += 1
    idx += idx and (-idx)

proc bitSum(tree: var seq[int], index: int): int =
  var idx = index
  result = 0
  while idx > 0:
    result += tree[idx]
    idx -= idx and (-idx)

var outputBuffer = ""

proc flushOutput() =
  stdout.write(outputBuffer)
  outputBuffer.setLen(0)

proc appendAnswer(answer: int64) =
  outputBuffer.add($answer)
  outputBuffer.add('\n')
  if outputBuffer.len >= flushBlockBytes:
    flushOutput()

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let sourceWord = readWord(inputData, scanPos)
  let targetWord = readWord(inputData, scanPos)
  let pairCount = nextInt(inputData, scanPos)

  var adjacencyMask: array[letterKinds, int]
  for pairIndex in 0 .. pairCount - 1:
    skipWhitespace(inputData, scanPos)
    let leftLetter = int(inputData[scanPos]) - firstLetterCode
    inc scanPos
    skipWhitespace(inputData, scanPos)
    let rightLetter = int(inputData[scanPos]) - firstLetterCode
    inc scanPos
    adjacencyMask[leftLetter] = adjacencyMask[leftLetter] or (1 shl rightLetter)
    adjacencyMask[rightLetter] = adjacencyMask[rightLetter] or (1 shl leftLetter)

  var possible = true
  var sourceFreq: array[letterKinds, int]
  var targetFreq: array[letterKinds, int]
  for offset in 0 .. sourceWord.length - 1:
    inc sourceFreq[int(inputData[sourceWord.start + offset]) - firstLetterCode]
  for offset in 0 .. targetWord.length - 1:
    inc targetFreq[int(inputData[targetWord.start + offset]) - firstLetterCode]
  for letterIndex in 0 .. letterKinds - 1:
    if sourceFreq[letterIndex] != targetFreq[letterIndex]:
      possible = false

  var answer: int64 = 0
  if possible and sourceWord.length > 0:
    var positionLists: array[letterKinds, seq[int]]
    for letterIndex in 0 .. letterKinds - 1:
      positionLists[letterIndex] = newSeq[int](targetFreq[letterIndex])
    var filled: array[letterKinds, int]
    for offset in 0 .. targetWord.length - 1:
      let letterIndex = int(inputData[targetWord.start + offset]) - firstLetterCode
      positionLists[letterIndex][filled[letterIndex]] = offset
      inc filled[letterIndex]

    var targetIndexAt = newSeq[int](sourceWord.length)
    for letterIndex in 0 .. letterKinds - 1:
      filled[letterIndex] = 0
    for offset in 0 .. sourceWord.length - 1:
      let letterIndex = int(inputData[sourceWord.start + offset]) - firstLetterCode
      targetIndexAt[offset] = positionLists[letterIndex][filled[letterIndex]]
      inc filled[letterIndex]

    var connectedNeighbours: array[letterKinds, seq[int]]
    for letterIndex in 0 .. letterKinds - 1:
      connectedNeighbours[letterIndex] = newSeq[int]()
      for otherIndex in 0 .. letterKinds - 1:
        if (adjacencyMask[letterIndex] and (1 shl otherIndex)) != 0:
          connectedNeighbours[letterIndex].add(otherIndex)

    var totalTree = newSeq[int](sourceWord.length + 1)
    var letterTrees: array[letterKinds, seq[int]]
    var letterTotals: array[letterKinds, int]
    for letterIndex in 0 .. letterKinds - 1:
      letterTrees[letterIndex] = newSeq[int](sourceWord.length + 1)

    for offset in 0 .. sourceWord.length - 1:
      let letterIndex = int(inputData[sourceWord.start + offset]) - firstLetterCode
      let positionIndex = targetIndexAt[offset] + 1
      let allInversions = offset - bitSum(totalTree, positionIndex)
      var connectedInversions = 0
      for neighbourIndex in connectedNeighbours[letterIndex]:
        connectedInversions += letterTotals[neighbourIndex] - bitSum(letterTrees[neighbourIndex], positionIndex)
      if connectedInversions != allInversions:
        possible = false
        break
      answer += int64(connectedInversions)
      bitAdd(totalTree, positionIndex)
      bitAdd(letterTrees[letterIndex], positionIndex)
      inc letterTotals[letterIndex]

  if not possible:
    outputBuffer.add("-1\n")
  else:
    appendAnswer(answer mod moduloBase)

flushOutput()

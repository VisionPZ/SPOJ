const flushBlockBytes = 1 shl 17

type
  TreeInfo = object
    totalCuts: int
    maxDepth: int
    firstCuts: int

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  return value

proc nextBitWordStart(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  let wordStart = i
  while i < inputData.len and (inputData[i] == '0' or inputData[i] == '1'):
    i = i + 1
  return wordStart

proc parseSubtree(inputData: string, wordEnd: int, i: var int): TreeInfo =
  if i >= wordEnd or inputData[i] == '0':
    if i < wordEnd: i = i + 1
    return TreeInfo(totalCuts: 0, maxDepth: 0, firstCuts: 0)
  i = i + 1
  let leftInfo = parseSubtree(inputData, wordEnd, i)
  let rightInfo = parseSubtree(inputData, wordEnd, i)
  result.totalCuts = 1 + leftInfo.totalCuts + rightInfo.totalCuts
  result.maxDepth = 1 + max(leftInfo.maxDepth, rightInfo.maxDepth)
  if leftInfo.maxDepth >= rightInfo.maxDepth:
    result.firstCuts = 1 + leftInfo.firstCuts
  else:
    result.firstCuts = 1 + leftInfo.totalCuts + rightInfo.firstCuts

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var i = 0
var outputBuffer: string
while true:
  let declaredLength = nextInt(inputData, i)
  if declaredLength == 0: break
  let wordStart = nextBitWordStart(inputData, i)
  var j = wordStart
  let wordEnd = i
  let subtreeInfo = parseSubtree(inputData, wordEnd, j)
  outputBuffer.add $subtreeInfo.firstCuts
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer

const flushBlockBytes = 1 shl 17

type
  TreeInfo = object
    totalCuts: int
    maxDepth: int
    firstCuts: int

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ': scanPos = scanPos + 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - 48
    scanPos = scanPos + 1
  return value

proc nextBitWordStart(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ': scanPos = scanPos + 1
  let wordStart = scanPos
  while scanPos < inputData.len and (inputData[scanPos] == '0' or inputData[scanPos] == '1'):
    scanPos = scanPos + 1
  return wordStart

proc parseSubtree(inputData: string, wordEnd: int, scanPos: var int): TreeInfo =
  if scanPos >= wordEnd or inputData[scanPos] == '0':
    if scanPos < wordEnd: scanPos = scanPos + 1
    return TreeInfo(totalCuts: 0, maxDepth: 0, firstCuts: 0)
  scanPos = scanPos + 1
  let leftInfo = parseSubtree(inputData, wordEnd, scanPos)
  let rightInfo = parseSubtree(inputData, wordEnd, scanPos)
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

var scanPos = 0
var outputBuffer: string
while true:
  let declaredLength = nextInt(inputData, scanPos)
  if declaredLength == 0: break
  let wordStart = nextBitWordStart(inputData, scanPos)
  var wordPos = wordStart
  let wordEnd = scanPos
  let subtreeInfo = parseSubtree(inputData, wordEnd, wordPos)
  outputBuffer.add $subtreeInfo.firstCuts
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer

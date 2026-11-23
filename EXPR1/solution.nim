const maxTermCount = 20
const maxOpenGroups = 20
const valueOffset = 180
const valueCount = 361
const impossibleCost = 1 shl 28
const tableSize = (maxOpenGroups + 1) * valueCount
const flushBlockBytes = 1 shl 17

proc skipWhitespace(inputData: string, scanPos: var int) =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos = scanPos + 1

proc nextSignedInt(inputData: string, scanPos: var int): int =
  skipWhitespace(inputData, scanPos)
  var negative = false
  if scanPos < inputData.len and (inputData[scanPos] == '-' or inputData[scanPos] == '+'):
    negative = inputData[scanPos] == '-'
    scanPos = scanPos + 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - 48
    scanPos = scanPos + 1
  if negative: return -value
  return value

proc nextTokenBounds(inputData: string, scanPos: var int): tuple[first: int, count: int] =
  skipWhitespace(inputData, scanPos)
  let first = scanPos
  while scanPos < inputData.len and inputData[scanPos] > ' ':
    scanPos = scanPos + 1
  result.first = first
  result.count = scanPos - first

proc clearCosts(costs: var array[0..tableSize - 1, int]) =
  for index in 0 .. tableSize - 1:
    costs[index] = impossibleCost

proc solveCase(termCount: int, targetValue: int, expressionStart: int, inputData: string): int =
  var termOperators: array[0..maxTermCount - 1, char]
  var termDigits: array[0..maxTermCount - 1, int]
  for termIndex in 0 .. termCount - 1:
    termOperators[termIndex] = inputData[expressionStart + 2 * termIndex]
    termDigits[termIndex] = int(inputData[expressionStart + 2 * termIndex + 1]) - 48

  var currentCosts: array[0..tableSize - 1, int]
  var closedCosts: array[0..tableSize - 1, int]
  var openedCosts: array[0..tableSize - 1, int]
  var followingCosts: array[0..tableSize - 1, int]
  clearCosts(currentCosts)
  currentCosts[valueOffset] = 0

  for boundary in 0 .. termCount:
    for valueIndex in 0 .. valueCount - 1:
      var best = impossibleCost
      for depth in countdown(maxOpenGroups, 0):
        let slot = depth * valueCount + valueIndex
        if currentCosts[slot] < best: best = currentCosts[slot]
        closedCosts[slot] = best

    for slot in 0 .. tableSize - 1:
      openedCosts[slot] = closedCosts[slot]
    if boundary >= 1 and boundary <= termCount - 1 and termOperators[boundary - 1] == '-':
      for depth in 0 .. maxOpenGroups - 1:
        for valueIndex in 0 .. valueCount - 1:
          let source = closedCosts[depth * valueCount + valueIndex]
          if source >= impossibleCost: continue
          let destination = (depth + 1) * valueCount + valueIndex
          if source + 1 < openedCosts[destination]:
            openedCosts[destination] = source + 1

    if boundary == termCount:
      var answer = impossibleCost
      let wantedIndex = targetValue + valueOffset
      for depth in 0 .. maxOpenGroups:
        let slot = depth * valueCount + wantedIndex
        if openedCosts[slot] < answer: answer = openedCosts[slot]
      if answer >= impossibleCost: return -1
      return answer

    clearCosts(followingCosts)
    let operatorSign = if termOperators[boundary] == '+': 1 else: -1
    let digitValue = termDigits[boundary]
    for depth in 0 .. maxOpenGroups:
      let flipSign = if (depth and 1) == 1: -1 else: 1
      let delta = operatorSign * flipSign * digitValue
      for valueIndex in 0 .. valueCount - 1:
        let source = openedCosts[depth * valueCount + valueIndex]
        if source >= impossibleCost: continue
        let nextValue = valueIndex + delta
        if nextValue < 0 or nextValue >= valueCount: continue
        let destination = depth * valueCount + nextValue
        if source < followingCosts[destination]:
          followingCosts[destination] = source

    swap currentCosts, followingCosts

  return -1

var inputData: string
var inputLine: string
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add "\n"

var scanPos = 0
let caseCount = nextSignedInt(inputData, scanPos)
var outputBuffer: string
for caseIndex in 1 .. caseCount:
  let termCount = nextSignedInt(inputData, scanPos) div 2
  let targetValue = nextSignedInt(inputData, scanPos)
  let expressionBounds = nextTokenBounds(inputData, scanPos)
  let answer = solveCase(termCount, targetValue, expressionBounds.first, inputData)
  if answer < 0:
    outputBuffer.add "NO\n"
  else:
    outputBuffer.add $answer
    outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer

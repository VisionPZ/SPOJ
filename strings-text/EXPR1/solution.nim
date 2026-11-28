const maxTermCount = 20
const maxOpenGroups = 20
const valueOffset = 180
const valueCount = 361
const impossibleCost = 1 shl 28
const tableSize = (maxOpenGroups + 1) * valueCount
const flushBlockBytes = 1 shl 17

proc skipWhitespace(inputData: string, i: var int) =
  while i < inputData.len and inputData[i] <= ' ':
    i = i + 1

proc nextSignedInt(inputData: string, i: var int): int =
  skipWhitespace(inputData, i)
  var negative = false
  if i < inputData.len and (inputData[i] == '-' or inputData[i] == '+'):
    negative = inputData[i] == '-'
    i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  if negative: return -value
  return value

proc nextTokenBounds(inputData: string, i: var int): tuple[first: int, count: int] =
  skipWhitespace(inputData, i)
  let first = i
  while i < inputData.len and inputData[i] > ' ':
    i = i + 1
  result.first = first
  result.count = i - first

proc clearCosts(costs: var array[0..tableSize - 1, int]) =
  for i in 0 .. tableSize - 1:
    costs[i] = impossibleCost

proc solveCase(termCount: int, targetValue: int, expressionStart: int, inputData: string): int =
  var termOperators: array[0..maxTermCount - 1, char]
  var termDigits: array[0..maxTermCount - 1, int]
  for i in 0 .. termCount - 1:
    termOperators[i] = inputData[expressionStart + 2 * i]
    termDigits[i] = int(inputData[expressionStart + 2 * i + 1]) - 48

  var currentCosts: array[0..tableSize - 1, int]
  var closedCosts: array[0..tableSize - 1, int]
  var openedCosts: array[0..tableSize - 1, int]
  var followingCosts: array[0..tableSize - 1, int]
  clearCosts(currentCosts)
  currentCosts[valueOffset] = 0

  for j in 0 .. termCount:
    for k in 0 .. valueCount - 1:
      var best = impossibleCost
      for l in countdown(maxOpenGroups, 0):
        let i = l * valueCount + k
        if currentCosts[i] < best: best = currentCosts[i]
        closedCosts[i] = best

    for i in 0 .. tableSize - 1:
      openedCosts[i] = closedCosts[i]
    if j >= 1 and j <= termCount - 1 and termOperators[j - 1] == '-':
      for l in 0 .. maxOpenGroups - 1:
        for k in 0 .. valueCount - 1:
          let source = closedCosts[l * valueCount + k]
          if source >= impossibleCost: continue
          let destination = (l + 1) * valueCount + k
          if source + 1 < openedCosts[destination]:
            openedCosts[destination] = source + 1

    if j == termCount:
      var answer = impossibleCost
      let wantedIndex = targetValue + valueOffset
      for l in 0 .. maxOpenGroups:
        let i = l * valueCount + wantedIndex
        if openedCosts[i] < answer: answer = openedCosts[i]
      if answer >= impossibleCost: return -1
      return answer

    clearCosts(followingCosts)
    let operatorSign = if termOperators[j] == '+': 1 else: -1
    let digitValue = termDigits[j]
    for l in 0 .. maxOpenGroups:
      let flipSign = if (l and 1) == 1: -1 else: 1
      let delta = operatorSign * flipSign * digitValue
      for k in 0 .. valueCount - 1:
        let source = openedCosts[l * valueCount + k]
        if source >= impossibleCost: continue
        let nextValue = k + delta
        if nextValue < 0 or nextValue >= valueCount: continue
        let destination = l * valueCount + nextValue
        if source < followingCosts[destination]:
          followingCosts[destination] = source

    swap currentCosts, followingCosts

  return -1

var inputData: string
var inputLine: string
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add "\n"

var i = 0
let caseCount = nextSignedInt(inputData, i)
var outputBuffer: string
for j in 1 .. caseCount:
  let termCount = nextSignedInt(inputData, i) div 2
  let targetValue = nextSignedInt(inputData, i)
  let expressionBounds = nextTokenBounds(inputData, i)
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

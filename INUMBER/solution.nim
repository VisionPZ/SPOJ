{.passC: "-O2".}
{.push checks: off.}
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxN = 1000
const stride = 1001
const maxStates = stride * maxN

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var visitMark = newSeq[int32](maxStates)
var parentState = newSeq[int32](maxStates)
var parentDigit = newSeq[int8](maxStates)
var bfsQueue = newSeq[int32](maxStates + 16)
var remainderTable = newSeq[int16](maxN * 10 + 10)
var caseMark = int32(0)

proc buildAnswer(startState: int): string =
  var digits: seq[int8] = @[]
  var cur = startState
  while cur >= 0:
    digits.add parentDigit[cur]
    cur = int(parentState[cur])
  var answerText = ""
  for k in 0..<digits.len:
    answerText.add char(firstDigitValue + int(digits[digits.len - 1 - k]))
  return answerText

proc solve(target: int): string =
  caseMark += 1
  for i in 0..<remainderTable.len:
    remainderTable[i] = int16(i mod target)
  var head = 0
  var tail = 0
  for digit in 1..9:
    if digit > target: break
    let remain = int(remainderTable[digit])
    let state = remain * stride + digit
    if visitMark[state] == caseMark: continue
    visitMark[state] = caseMark
    parentState[state] = -1
    parentDigit[state] = int8(digit)
    if remain == 0 and digit == target: return buildAnswer(state)
    bfsQueue[tail] = int32(state)
    tail += 1
  while head < tail:
    let state = int(bfsQueue[head])
    head += 1
    let remain = state div stride
    let digitSum = state mod stride
    for digit in 0..9:
      let nextSum = digitSum + digit
      if nextSum > target: break
      let nextRemain = int(remainderTable[remain * 10 + digit])
      let nextState = nextRemain * stride + nextSum
      if visitMark[nextState] == caseMark: continue
      visitMark[nextState] = caseMark
      parentState[nextState] = int32(state)
      parentDigit[nextState] = int8(digit)
      if nextRemain == 0 and nextSum == target: return buildAnswer(nextState)
      bfsQueue[tail] = int32(nextState)
      tail += 1
  return ""

var outputBuffer = ""
proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for j in 0..<caseCount:
  let target = nextInt(inputData, scanPos)
  appendOutput(solve(target))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

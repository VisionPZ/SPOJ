const flushBlockBytes = 1 shl 18
const firstDigitValue = 48

var outputBuffer = ""

proc rotateFraction(cfDigits: var seq[int], isInfinite: var bool, isNegative: var bool) =
  if isInfinite:
    isInfinite = false
    isNegative = false
    cfDigits[0] = 0
    cfDigits.setLen(1)
    return
  let digitCount = cfDigits.len
  let front = cfDigits[digitCount - 1]
  if digitCount == 1 and front == 0:
    isInfinite = true
  elif front == 0:
    cfDigits.setLen(digitCount - 1)
  else:
    cfDigits.add 0
  isNegative = not isNegative

proc addOneToFraction(cfDigits: var seq[int], isNegative: var bool) =
  let digitCount = cfDigits.len
  let front = cfDigits[digitCount - 1]
  if not isNegative:
    cfDigits[digitCount - 1] = front + 1
  elif front >= 2:
    cfDigits[digitCount - 1] = front - 1
  elif front == 1:
    if digitCount == 1:
      isNegative = false
      cfDigits[0] = 0
    else:
      cfDigits[digitCount - 1] = 0
  else:
    let second = cfDigits[digitCount - 2]
    if second >= 2:
      cfDigits[digitCount - 2] = second - 1
      cfDigits[digitCount - 1] = 1
      cfDigits.add 0
    elif digitCount >= 3:
      cfDigits[digitCount - 3] = cfDigits[digitCount - 3] + 1
      cfDigits[digitCount - 2] = 0
      cfDigits.setLen(digitCount - 1)
    else:
      cfDigits[0] = 0
      cfDigits.setLen(1)
    isNegative = false


proc countUndoSteps(cfDigits: var seq[int], isInfinite: var bool, isNegative: var bool): int =
  if isInfinite:
    return 1
  var answer = 0
  while true:
    if not isInfinite and cfDigits.len == 1 and cfDigits[0] == 0:
      return answer
    if isNegative:
      let digitCount = cfDigits.len
      let front = cfDigits[digitCount - 1]
      if front >= 2:
        answer += front - 1
        cfDigits[digitCount - 1] = 1
      elif front == 0 and digitCount >= 2 and cfDigits[digitCount - 2] >= 2:
        answer += 3 * (cfDigits[digitCount - 2] - 1)
        cfDigits[digitCount - 2] = 1
      else:
        addOneToFraction(cfDigits, isNegative)
        answer += 1
    else:
      rotateFraction(cfDigits, isInfinite, isNegative)
      answer += 1

proc main() =
  var inputData = ""
  var line = ""
  while readLine(stdin, line):
    inputData.add line
    inputData.add '\n'
  let dataLength = inputData.len
  var i = 0
  while i < dataLength:
    while i < dataLength and (inputData[i] < '0' or inputData[i] > '9'):
      i += 1
    if i >= dataLength:
      break
    var moveCount = 0
    while i < dataLength and inputData[i] >= '0' and inputData[i] <= '9':
      moveCount = moveCount * 10 + (ord(inputData[i]) - firstDigitValue)
      i += 1
    var cfDigits: seq[int] = @[0]
    var isInfinite = false
    var isNegative = false
    for j in 0 ..< moveCount:
      while i < dataLength and inputData[i] != 'S' and inputData[i] != 'R':
        i += 1
      if i >= dataLength:
        break
      let moveLetter = inputData[i]
      i += 1
      if moveLetter == 'R':
        rotateFraction(cfDigits, isInfinite, isNegative)
      elif not isInfinite:
        addOneToFraction(cfDigits, isNegative)
    let answer = countUndoSteps(cfDigits, isInfinite, isNegative)
    outputBuffer.add $answer
    outputBuffer.add '\n'
    if outputBuffer.len >= flushBlockBytes:
      stdout.write outputBuffer
      outputBuffer.setLen 0
  if outputBuffer.len > 0:
    stdout.write outputBuffer
    outputBuffer.setLen 0

main()

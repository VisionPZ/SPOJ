const flushBlockBytes = 1 shl 17

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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc repeatedDigitText(digitValue: int, repeatCount: int): string =
  result = ""
  for repeatIndex in 0 .. repeatCount - 1:
    result.add chr(48 + digitValue)

proc isBetter(candidate: string, currentBest: string): bool =
  if candidate.len == 0:
    return false
  if currentBest.len == 0:
    return true
  if candidate.len != currentBest.len:
    return candidate.len < currentBest.len
  return candidate < currentBest

proc singleDigitAnswer(digitValue: int, modulusValue: int): string =
  var remainderValue = digitValue mod modulusValue
  if remainderValue == 0:
    return repeatedDigitText(digitValue, 1)
  for lengthValue in 2 .. modulusValue + 1:
    remainderValue = (remainderValue * 10 + digitValue) mod modulusValue
    if remainderValue == 0:
      return repeatedDigitText(digitValue, lengthValue)
  return ""

proc reconstructAnswer(parentRemainder: seq[int], parentDigit: seq[int], tailRemainder: int, lastDigit: int): string =
  var reversedDigits = newSeq[int]()
  var cursor = tailRemainder
  while cursor >= 0:
    reversedDigits.add parentDigit[cursor]
    cursor = parentRemainder[cursor]
  result = ""
  var indexValue = reversedDigits.len - 1
  while indexValue >= 0:
    result.add chr(48 + reversedDigits[indexValue])
    indexValue -= 1
  result.add chr(48 + lastDigit)

proc pairDigitAnswer(firstDigit: int, secondDigit: int, modulusValue: int, parentRemainder: var seq[int], parentDigit: var seq[int], queue: var seq[int]): string =
  for indexValue in 0 .. modulusValue - 1:
    parentRemainder[indexValue] = -2
  queue.setLen 0
  var queueHead = 0
  var lowDigit = firstDigit
  var highDigit = secondDigit
  if lowDigit > highDigit:
    let previousDigit = lowDigit
    lowDigit = highDigit
    highDigit = previousDigit
  for startDigit in [lowDigit, highDigit]:
    if startDigit == 0:
      continue
    let startRemainder = startDigit mod modulusValue
    if startRemainder == 0:
      return repeatedDigitText(startDigit, 1)
    if parentRemainder[startRemainder] == -2:
      parentRemainder[startRemainder] = -1
      parentDigit[startRemainder] = startDigit
      queue.add startRemainder
  while queueHead < queue.len:
    let currentRemainder = queue[queueHead]
    queueHead += 1
    for digitValue in [lowDigit, highDigit]:
      let nextRemainder = (currentRemainder * 10 + digitValue) mod modulusValue
      if nextRemainder == 0:
        return reconstructAnswer(parentRemainder, parentDigit, currentRemainder, digitValue)
      if parentRemainder[nextRemainder] == -2:
        parentRemainder[nextRemainder] = currentRemainder
        parentDigit[nextRemainder] = digitValue
        queue.add nextRemainder
  return ""

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var answerLines = newSeq[string]()
while scanPos < inputData.len:
  let divisorValue = nextInt(inputData, scanPos)
  if divisorValue == 0:
    break
  var bestSingle = ""
  for digitValue in 1 .. 9:
    let candidate = singleDigitAnswer(digitValue, divisorValue)
    if isBetter(candidate, bestSingle):
      bestSingle = candidate
  if bestSingle.len > 0:
    answerLines.add bestSingle
  else:
    var parentRemainder = newSeq[int](divisorValue)
    var parentDigit = newSeq[int](divisorValue)
    var queue = newSeq[int]()
    var bestPair = ""
    for firstDigit in 0 .. 8:
      for secondDigit in firstDigit + 1 .. 9:
        let candidate = pairDigitAnswer(firstDigit, secondDigit, divisorValue, parentRemainder, parentDigit, queue)
        if isBetter(candidate, bestPair):
          bestPair = candidate
    answerLines.add bestPair
for answerIndex in 0 .. answerLines.len - 1:
  appendOutput(answerLines[answerIndex])
  if answerIndex < answerLines.len - 1:
    appendOutput " "
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

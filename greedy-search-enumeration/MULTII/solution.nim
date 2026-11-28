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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var caseNumber = 0
while true:
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  if scanPos >= inputData.len:
    break
  caseNumber += 1
  let divisor = nextInt(inputData, scanPos)
  let forbiddenCount = nextInt(inputData, scanPos)
  var forbiddenDigits = newSeq[bool](10)
  for digitIndex in 0 .. forbiddenCount - 1:
    let forbiddenDigit = nextInt(inputData, scanPos)
    forbiddenDigits[forbiddenDigit] = true
  var visitedRemainder = newSeq[bool](divisor)
  var parentRemainder = newSeq[int](divisor)
  var parentDigit = newSeq[int](divisor)
  var remainderQueue = newSeq[int](divisor)
  var queueHead = 0
  var queueTail = 0
  var foundRemainder = false
  for digitValue in 1 .. 9:
    if forbiddenDigits[digitValue]:
      continue
    let startRemainder = digitValue mod divisor
    if not visitedRemainder[startRemainder]:
      visitedRemainder[startRemainder] = true
      parentRemainder[startRemainder] = -1
      parentDigit[startRemainder] = digitValue
      remainderQueue[queueTail] = startRemainder
      queueTail += 1
      if startRemainder == 0:
        foundRemainder = true
        break
  while not foundRemainder and queueHead < queueTail:
    let currentRemainder = remainderQueue[queueHead]
    queueHead += 1
    for digitValue in 0 .. 9:
      if forbiddenDigits[digitValue]:
        continue
      let nextRemainder = (currentRemainder * 10 + digitValue) mod divisor
      if not visitedRemainder[nextRemainder]:
        visitedRemainder[nextRemainder] = true
        parentRemainder[nextRemainder] = currentRemainder
        parentDigit[nextRemainder] = digitValue
        remainderQueue[queueTail] = nextRemainder
        queueTail += 1
        if nextRemainder == 0:
          foundRemainder = true
          break
  appendOutput("Case " & $caseNumber & ": ")
  if not foundRemainder:
    appendOutput("-1")
  else:
    var reversedDigits = ""
    var cursor = 0
    while parentRemainder[cursor] != -1:
      reversedDigits.add chr(parentDigit[cursor] + 48)
      cursor = parentRemainder[cursor]
    reversedDigits.add chr(parentDigit[cursor] + 48)
    for digitIndex in countdown(reversedDigits.len - 1, 0):
      outputBuffer.add reversedDigits[digitIndex]
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0

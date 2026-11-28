{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var scanPos = 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  while scanPos < inputData.len and (inputData[scanPos] < 'a' or inputData[scanPos] > 'z'):
    scanPos += 1
  let strStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] >= 'a' and inputData[scanPos] <= 'z':
    scanPos += 1
  let strLen = scanPos - strStart

  var straightMatch = newSeq[uint16](strLen + 1)
  if strLen >= 2:
    var prevHorizontal = newSeq[uint16](strLen + 1)
    var curHorizontal = newSeq[uint16](strLen + 1)
    var curVertical = newSeq[uint16](strLen + 1)
    for j in 0..strLen:
      prevHorizontal[j] = uint16(j)
    for i in 1..strLen:
      curVertical[0] = 0
      let leftLetter = inputData[strStart + i - 1]
      for j in 1..strLen:
        if leftLetter == inputData[strStart + j - 1]:
          curHorizontal[j] = curVertical[j - 1]
          curVertical[j] = prevHorizontal[j]
        else:
          let across = curVertical[j - 1]
          let above = prevHorizontal[j]
          curHorizontal[j] = if across > above: across else: above
          curVertical[j] = if across < above: across else: above
      if i < strLen:
        var reached = 0
        for j in (i + 1)..strLen:
          if curHorizontal[j] <= uint16(i):
            reached += 1
        straightMatch[i] = uint16(reached)
      swap prevHorizontal, curHorizontal

  var revMatch = newSeq[uint16](strLen + 1)
  if strLen >= 2:
    for j in countdown(strLen - 1, 1):
      for p in countdown(j - 1, 0):
        if inputData[strStart + p] == inputData[strStart + j]:
          let candidate = (if p > 0: int(revMatch[p - 1]) else: 0) + 1
          if candidate > int(revMatch[p]):
            revMatch[p] = uint16(candidate)
      for p in 1..<strLen:
        if revMatch[p - 1] > revMatch[p]:
          revMatch[p] = revMatch[p - 1]
      revMatch[j] = revMatch[j - 1]

  var bestLength = 0
  var bestCut = 1
  for cut in 1..<strLen:
    let oneSide = int(straightMatch[cut])
    let turnedSide = int(revMatch[cut])
    let pairLength = 2 * (if oneSide > turnedSide: oneSide else: turnedSide)
    if pairLength > bestLength:
      bestLength = pairLength
      bestCut = cut
  appendOutput($(bestLength) & " " & $(bestCut) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0

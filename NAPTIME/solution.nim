{.push optimization: speed.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const impossibleValue = -1

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

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

proc solveRun(utilities: seq[int], periodCount: int, bedCount: int,
              wrapFirst: bool): int =
  var prevOutside = newSeq[int](bedCount + 1)
  var prevInside = newSeq[int](bedCount + 1)
  var nextOutside = newSeq[int](bedCount + 1)
  var nextInside = newSeq[int](bedCount + 1)
  for j in 0..bedCount:
    prevOutside[j] = impossibleValue
    prevInside[j] = impossibleValue
  if wrapFirst:
    prevInside[1] = utilities[1]
  else:
    prevOutside[0] = 0
    prevInside[1] = 0
  for i in 2..periodCount:
    let previousTop = if i - 1 < bedCount: i - 1 else: bedCount
    for j in 0..previousTop:
      var bestOutside = impossibleValue
      var bestInside = impossibleValue
      let outsideValue = prevOutside[j]
      let insideValue = prevInside[j]
      if outsideValue >= 0:
        bestOutside = outsideValue
        bestInside = outsideValue
      if insideValue >= 0:
        if insideValue > bestOutside:
          bestOutside = insideValue
        let stayValue = insideValue + utilities[i]
        if stayValue > bestInside:
          bestInside = stayValue
      nextOutside[j] = bestOutside
      if j < bedCount:
        nextInside[j + 1] = bestInside
    if previousTop < bedCount:
      nextOutside[previousTop + 1] = impossibleValue
    nextInside[0] = impossibleValue
    swap(prevOutside, nextOutside)
    swap(prevInside, nextInside)
  if wrapFirst:
    return prevInside[bedCount]
  let outsideAnswer = prevOutside[bedCount]
  let insideAnswer = prevInside[bedCount]
  return if outsideAnswer > insideAnswer: outsideAnswer else: insideAnswer

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let periodCount = nextInt(inputData, scanPos)
  let bedCount = nextInt(inputData, scanPos)
  var utilities = newSeq[int](periodCount + 1)
  for i in 1..periodCount:
    utilities[i] = nextInt(inputData, scanPos)
  let plainAnswer = solveRun(utilities, periodCount, bedCount, false)
  let wrappedAnswer = solveRun(utilities, periodCount, bedCount, true)
  let bestAnswer = if plainAnswer > wrappedAnswer: plainAnswer else: wrappedAnswer
  appendOutput($(bestAnswer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

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

var currentPadCount = 0
var currentJumpDistance = 0
var memoKeys = newSeq[string](0)
var memoValues = newSeq[int](0)

proc stateKey(stepIndex: int, gaps: seq[int], slacks: seq[int]): string =
  result = $stepIndex
  for gapValue in gaps:
    result.add '|'
    result.add $gapValue
  for slackValue in slacks:
    result.add '|'
    result.add $slackValue

proc fewestSwims(stepIndex: int, gaps: seq[int], slacks: seq[int]): int =
  if stepIndex == currentPadCount + 1:
    return 0
  let key = stateKey(stepIndex, gaps, slacks)
  for memoIndex in 0 .. memoKeys.len - 1:
    if memoKeys[memoIndex] == key:
      return memoValues[memoIndex]
  var bestCost = 1 shl 29
  let neededPull = gaps[stepIndex] - currentJumpDistance
  if neededPull <= 0:
    bestCost = fewestSwims(stepIndex + 1, gaps, slacks)
  else:
    bestCost = 1 + fewestSwims(stepIndex + 1, gaps, slacks)
    var availablePull = 0
    if stepIndex < currentPadCount:
      for slackIndex in stepIndex + 1 .. currentPadCount:
        availablePull = availablePull + slacks[slackIndex]
    if neededPull <= availablePull:
      var nextGaps = gaps
      var nextSlacks = slacks
      nextGaps[stepIndex] = nextGaps[stepIndex] - neededPull
      var remainingPull = neededPull
      var slackIndex = stepIndex + 1
      while remainingPull > 0 and slackIndex <= currentPadCount:
        let usedSlack = min(remainingPull, nextSlacks[slackIndex])
        nextSlacks[slackIndex] = nextSlacks[slackIndex] - usedSlack
        nextGaps[slackIndex] = nextGaps[slackIndex] + usedSlack
        remainingPull = remainingPull - usedSlack
        slackIndex += 1
      let jumpCost = fewestSwims(stepIndex + 1, nextGaps, nextSlacks)
      if jumpCost < bestCost:
        bestCost = jumpCost
  memoKeys.add key
  memoValues.add bestCost
  return bestCost

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let padCount = nextInt(inputData, scanPos)
  let jumpDistance = nextInt(inputData, scanPos)
  currentPadCount = padCount
  currentJumpDistance = jumpDistance
  var positions = newSeq[int](padCount + 2)
  for positionIndex in 0 .. padCount + 1:
    positions[positionIndex] = nextInt(inputData, scanPos)
  var gaps = newSeq[int](padCount + 1)
  var slacks = newSeq[int](padCount + 1)
  for gapIndex in 0 .. padCount:
    gaps[gapIndex] = positions[gapIndex + 1] - positions[gapIndex]
  for ropeIndex in 0 .. padCount:
    let ropeLength = nextInt(inputData, scanPos)
    slacks[ropeIndex] = ropeLength - gaps[ropeIndex]

  memoKeys = newSeq[string](0)
  memoValues = newSeq[int](0)
  let answer = fewestSwims(0, gaps, slacks)
  appendOutput("Case " & $caseIndex & ": " & $answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

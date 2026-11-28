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

proc movesToPeg(startPegs: seq[int], discCount: int, targetPeg: int): int64 =
  var totalMoves: int64 = 0
  var wantedPeg = targetPeg
  var discIndex = discCount
  while discIndex >= 1:
    if startPegs[discIndex] != wantedPeg:
      totalMoves = totalMoves + (int64(1) shl (discIndex - 1))
      wantedPeg = 6 - startPegs[discIndex] - wantedPeg
    discIndex -= 1
  return totalMoves

while true:
  let discCount = nextInt(inputData, scanPos)
  if discCount == 0:
    break
  var startPegs = newSeq[int](discCount + 1)
  var finalPegs = newSeq[int](discCount + 1)
  for discIndex in 1 .. discCount:
    startPegs[discIndex] = nextInt(inputData, scanPos)
  for discIndex in 1 .. discCount:
    finalPegs[discIndex] = nextInt(inputData, scanPos)
  var totalMoves: int64 = 0
  var discIndex = discCount
  while discIndex >= 1:
    if startPegs[discIndex] != finalPegs[discIndex]:
      let sourcePeg = startPegs[discIndex]
      let targetPeg = finalPegs[discIndex]
      let sparePeg = 6 - sourcePeg - targetPeg
      let smallerDiscs = discIndex - 1
      let oneJump: int64 = movesToPeg(startPegs, smallerDiscs, sparePeg) + 1 +
                           movesToPeg(finalPegs, smallerDiscs, sparePeg)
      let twoJumps: int64 = movesToPeg(startPegs, smallerDiscs, targetPeg) +
                            (int64(1) shl smallerDiscs) + 1 +
                            movesToPeg(finalPegs, smallerDiscs, sourcePeg)
      if oneJump < twoJumps:
        totalMoves = oneJump
      else:
        totalMoves = twoJumps
      break
    discIndex -= 1
  appendOutput($totalMoves)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

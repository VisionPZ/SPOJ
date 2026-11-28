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

proc circularDistance(boxCount: int, firstBox: int, secondBox: int): int =
  let direct = abs(firstBox - secondBox)
  if direct < boxCount - direct:
    return direct
  return boxCount - direct

proc arrangementCost(boxCount: int, assignment: seq[int]): int64 =
  var total: int64 = 0
  for boxIndex in 0 .. boxCount - 1:
    if assignment[boxIndex] >= 0:
      total += int64(circularDistance(boxCount, boxIndex, assignment[boxIndex]))
  return total

proc shiftBlockLeft(boxCount: int, sourceBox: int, leftmostBox: int,
                    assignment: seq[int]): seq[int] =
  var shifted = assignment
  var displaced = sourceBox
  var cursor = leftmostBox
  while true:
    cursor = (cursor + boxCount - 1) mod boxCount
    swap(shifted[cursor], displaced)
    if displaced == -1:
      break
  return shifted

proc shiftBlockRight(boxCount: int, sourceBox: int, rightmostBox: int,
                     assignment: seq[int]): seq[int] =
  var shifted = assignment
  var displaced = sourceBox
  var cursor = rightmostBox
  while true:
    cursor = (cursor + 1) mod boxCount
    swap(shifted[cursor], displaced)
    if displaced == -1:
      break
  return shifted

let testCount = nextInt(inputData, scanPos)

for testIndex in 0 .. testCount - 1:
  let boxCount = nextInt(inputData, scanPos)
  var spareBalls = newSeq[int](boxCount)
  var assignment = newSeq[int](boxCount)
  for boxIndex in 0 .. boxCount - 1:
    let ballCount = nextInt(inputData, scanPos)
    assignment[boxIndex] = -1
    if ballCount > 0:
      spareBalls[boxIndex] = ballCount - 1
      assignment[boxIndex] = boxIndex

  for sourceBox in 0 .. boxCount - 1:
    while spareBalls[sourceBox] > 0:
      spareBalls[sourceBox] -= 1
      var leftmostBox = sourceBox
      while assignment[leftmostBox] != sourceBox:
        leftmostBox = (leftmostBox + 1) mod boxCount
      while assignment[(leftmostBox + boxCount - 1) mod boxCount] == sourceBox:
        leftmostBox = (leftmostBox + boxCount - 1) mod boxCount

      var rightmostBox = sourceBox
      while assignment[rightmostBox] != sourceBox:
        rightmostBox = (rightmostBox + boxCount - 1) mod boxCount
      while assignment[(rightmostBox + 1) mod boxCount] == sourceBox:
        rightmostBox = (rightmostBox + 1) mod boxCount

      let leftPlan = shiftBlockLeft(boxCount, sourceBox, leftmostBox, assignment)
      let rightPlan = shiftBlockRight(boxCount, sourceBox, rightmostBox, assignment)
      if arrangementCost(boxCount, leftPlan) <= arrangementCost(boxCount, rightPlan):
        assignment = leftPlan
      else:
        assignment = rightPlan

  appendOutput($(arrangementCost(boxCount, assignment)))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

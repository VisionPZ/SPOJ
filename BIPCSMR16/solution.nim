const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let firstYearCount = int64(nextInt(inputData, scanPos))
  let secondYearCount = int64(nextInt(inputData, scanPos))
  let thirdYearCount = int64(nextInt(inputData, scanPos))
  let totalStudents = firstYearCount + secondYearCount + thirdYearCount
  let largestGroup = max(max(firstYearCount, secondYearCount), thirdYearCount)
  let otherStudents = totalStudents - largestGroup
  let thirdOfTotal = totalStudents div 3
  var teamCount: int64 = 0
  if 2 * thirdOfTotal >= largestGroup:
    teamCount = thirdOfTotal
  else:
    let halfCap = (largestGroup - 1) div 2
    if otherStudents < halfCap:
      teamCount = otherStudents
    else:
      teamCount = halfCap
  appendOutput($(teamCount))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

const firstDigitValue = 48
const firstUpperCaseValue = 65
const firstLowerCaseValue = 97
const base36 = 36
const problemCount = 9
const maxTeamCount = 62
const teamSlotCount = 1 shl 12
const flushBlockBytes = 1 shl 17
const acceptedMark = 'A'

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc skipWhitespace(data: string, position: var int) =
  while position < data.len and data[position] <= ' ':
    position += 1

proc scanInteger(data: string, position: var int): int =
  skipWhitespace(data, position)
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

proc scanTokenSpan(data: string, position: var int): tuple[first: int, last: int] =
  skipWhitespace(data, position)
  let tokenFirst = position
  while position < data.len and data[position] > ' ':
    position += 1
  return (tokenFirst, position)

proc encodeTeam(data: string, tokenFirst: int, tokenLast: int): int =
  var code = 0
  for charIndex in tokenFirst..<tokenLast:
    let character = data[charIndex]
    if character >= '0' and character <= '9':
      code = code * base36 + int(character) - firstDigitValue
    else:
      code = code * base36 + int(character) - firstLowerCaseValue + 10
  return code

var outputBuffer = ""

proc flushIfNeeded(buffer: var string) =
  if buffer.len >= flushBlockBytes:
    stdout.write buffer
    buffer.setLen 0

proc appendAverage(numerator: int, denominator: int, buffer: var string) =
  let scaledNumerator = numerator * 100
  let roundedCents = (2 * scaledNumerator + denominator) div (2 * denominator)
  buffer.add $(roundedCents div 100)
  buffer.add '.'
  let fractionPart = roundedCents mod 100
  if fractionPart < 10:
    buffer.add '0'
  buffer.add $fractionPart

var teamSlotCodes = newSeq[int](teamSlotCount)
var teamSlotIndices = newSeq[int](teamSlotCount)
var solvedFlags = newSeq[bool](maxTeamCount * problemCount)
var submissionCounts = newSeq[int](maxTeamCount * problemCount)
var acceptedPerProblem = newSeq[int](problemCount)
var submissionSumPerProblem = newSeq[int](problemCount)
var timeSumPerProblem = newSeq[int](problemCount)

let caseCount = scanInteger(inputData, scanPos)
for caseIndex in 0..<caseCount:
  for slotIndex in 0..<teamSlotCount:
    teamSlotIndices[slotIndex] = -1
  for pairIndex in 0..<maxTeamCount * problemCount:
    solvedFlags[pairIndex] = false
    submissionCounts[pairIndex] = 0
  for problemIndex in 0..<problemCount:
    acceptedPerProblem[problemIndex] = 0
    submissionSumPerProblem[problemIndex] = 0
    timeSumPerProblem[problemIndex] = 0

  let submissionCount = scanInteger(inputData, scanPos)
  var nextTeamIndex = 0
  for submissionIndex in 0..<submissionCount:
    let submissionTime = scanInteger(inputData, scanPos)
    let teamSpan = scanTokenSpan(inputData, scanPos)
    let problemSpan = scanTokenSpan(inputData, scanPos)
    let resultSpan = scanTokenSpan(inputData, scanPos)
    let problemIndex = int(inputData[problemSpan.first]) - firstUpperCaseValue
    let isAccepted = inputData[resultSpan.first] == acceptedMark
    let teamCode = encodeTeam(inputData, teamSpan.first, teamSpan.last)
    var slotIndex = teamCode and (teamSlotCount - 1)
    while teamSlotIndices[slotIndex] != -1 and teamSlotCodes[slotIndex] != teamCode:
      slotIndex = (slotIndex + 1) and (teamSlotCount - 1)
    if teamSlotIndices[slotIndex] == -1:
      teamSlotCodes[slotIndex] = teamCode
      teamSlotIndices[slotIndex] = nextTeamIndex
      nextTeamIndex += 1
    let teamIndex = teamSlotIndices[slotIndex]
    let pairIndex = teamIndex * problemCount + problemIndex
    if not solvedFlags[pairIndex]:
      submissionCounts[pairIndex] += 1
      if isAccepted:
        solvedFlags[pairIndex] = true
        acceptedPerProblem[problemIndex] += 1
        submissionSumPerProblem[problemIndex] += submissionCounts[pairIndex]
        timeSumPerProblem[problemIndex] += submissionTime

  for problemIndex in 0..<problemCount:
    outputBuffer.add chr(firstUpperCaseValue + problemIndex)
    outputBuffer.add ' '
    outputBuffer.add $acceptedPerProblem[problemIndex]
    outputBuffer.add ' '
    if acceptedPerProblem[problemIndex] > 0:
      appendAverage(submissionSumPerProblem[problemIndex],
                    acceptedPerProblem[problemIndex], outputBuffer)
      outputBuffer.add ' '
      appendAverage(timeSumPerProblem[problemIndex],
                    acceptedPerProblem[problemIndex], outputBuffer)
      outputBuffer.add ' '
    outputBuffer.add '\n'
    flushIfNeeded(outputBuffer)

stdout.write outputBuffer

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

var i = 0

proc skipWhitespace(data: string, i: var int) =
  while i < data.len and data[i] <= ' ':
    i += 1

proc scanInteger(data: string, i: var int): int =
  skipWhitespace(data, i)
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

proc scanTokenSpan(data: string, i: var int): tuple[first: int, last: int] =
  skipWhitespace(data, i)
  let tokenFirst = i
  while i < data.len and data[i] > ' ':
    i += 1
  return (tokenFirst, i)

proc encodeTeam(data: string, tokenFirst: int, tokenLast: int): int =
  var code = 0
  for i in tokenFirst..<tokenLast:
    let character = data[i]
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

let caseCount = scanInteger(inputData, i)
for j in 0..<caseCount:
  for k in 0..<teamSlotCount:
    teamSlotIndices[k] = -1
  for l in 0..<maxTeamCount * problemCount:
    solvedFlags[l] = false
    submissionCounts[l] = 0
  for k in 0..<problemCount:
    acceptedPerProblem[k] = 0
    submissionSumPerProblem[k] = 0
    timeSumPerProblem[k] = 0

  let submissionCount = scanInteger(inputData, i)
  var nextTeamIndex = 0
  for k in 0..<submissionCount:
    let submissionTime = scanInteger(inputData, i)
    let teamSpan = scanTokenSpan(inputData, i)
    let problemSpan = scanTokenSpan(inputData, i)
    let resultSpan = scanTokenSpan(inputData, i)
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
    let l = teamIndex * problemCount + problemIndex
    if not solvedFlags[l]:
      submissionCounts[l] += 1
      if isAccepted:
        solvedFlags[l] = true
        acceptedPerProblem[problemIndex] += 1
        submissionSumPerProblem[problemIndex] += submissionCounts[l]
        timeSumPerProblem[problemIndex] += submissionTime

  for k in 0..<problemCount:
    outputBuffer.add chr(firstUpperCaseValue + k)
    outputBuffer.add ' '
    outputBuffer.add $acceptedPerProblem[k]
    outputBuffer.add ' '
    if acceptedPerProblem[k] > 0:
      appendAverage(submissionSumPerProblem[k],
                    acceptedPerProblem[k], outputBuffer)
      outputBuffer.add ' '
      appendAverage(timeSumPerProblem[k],
                    acceptedPerProblem[k], outputBuffer)
      outputBuffer.add ' '
    outputBuffer.add '\n'
    flushIfNeeded(outputBuffer)

stdout.write outputBuffer

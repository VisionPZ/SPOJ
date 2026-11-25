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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1

proc tokenInt(token: string): int =
  result = 0
  for charIndex in 0 .. token.len - 1:
    result = result * 10 + int(token[charIndex]) - 48

type PersonResult = object
  personName: string
  descendantCount: int

proc comesBefore(left: PersonResult, right: PersonResult): bool =
  if left.descendantCount != right.descendantCount:
    return left.descendantCount > right.descendantCount
  return left.personName < right.personName

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var personNames = newSeq[string]()
var parentIndex = newSeq[int]()
var descendantCounts = newSeq[int]()

proc findPerson(name: string): int =
  for personIndex in 0 .. personNames.len - 1:
    if personNames[personIndex] == name:
      return personIndex
  personNames.add name
  parentIndex.add -1
  descendantCounts.add 0
  return personNames.len - 1

let testCount = tokenInt(nextWord(inputData, scanPos))
for caseIndex in 1 .. testCount:
  let lineCount = tokenInt(nextWord(inputData, scanPos))
  let depthTarget = tokenInt(nextWord(inputData, scanPos))
  personNames = newSeq[string]()
  parentIndex = newSeq[int]()
  descendantCounts = newSeq[int]()
  for lineIndex in 0 .. lineCount - 1:
    let ownerName = nextWord(inputData, scanPos)
    let ownerIndex = findPerson(ownerName)
    let childTotal = tokenInt(nextWord(inputData, scanPos))
    for childIndex in 0 .. childTotal - 1:
      let childName = nextWord(inputData, scanPos)
      let childPerson = findPerson(childName)
      parentIndex[childPerson] = ownerIndex
  for personIndex in 0 .. personNames.len - 1:
    var ancestor = personIndex
    for stepIndex in 0 .. depthTarget - 1:
      ancestor = parentIndex[ancestor]
      if ancestor == -1:
        break
    if ancestor != -1:
      descendantCounts[ancestor] += 1
  var candidates = newSeq[PersonResult]()
  for personIndex in 0 .. personNames.len - 1:
    if descendantCounts[personIndex] > 0:
      candidates.add PersonResult(personName: personNames[personIndex],
                                   descendantCount: descendantCounts[personIndex])
  for sortIndex in 1 .. candidates.len - 1:
    let currentPerson = candidates[sortIndex]
    var insertIndex = sortIndex - 1
    while insertIndex >= 0 and comesBefore(currentPerson, candidates[insertIndex]):
      candidates[insertIndex + 1] = candidates[insertIndex]
      insertIndex -= 1
    candidates[insertIndex + 1] = currentPerson
  appendOutput("Tree " & $caseIndex & ":\n")
  var cutoffCount = -1
  if candidates.len >= 3:
    cutoffCount = candidates[2].descendantCount
  var printedCount = 0
  for candidate in candidates:
    if printedCount < 3 or (cutoffCount != -1 and candidate.descendantCount == cutoffCount):
      appendOutput(candidate.personName & " " & $candidate.descendantCount & "\n")
      printedCount += 1
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

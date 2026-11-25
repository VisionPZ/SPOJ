import algorithm

const flushBlockBytes = 1 shl 17

type QueryRecord = object
  leftEnd: int
  rightEnd: int
  timeIndex: int
  answerIndex: int
  leftBlock: int
  rightBlock: int

proc compareQueryRecords(leftQuery, rightQuery: QueryRecord): int =
  if leftQuery.leftBlock != rightQuery.leftBlock:
    if leftQuery.leftBlock < rightQuery.leftBlock:
      return -1
    return 1
  if leftQuery.rightBlock != rightQuery.rightBlock:
    if (leftQuery.leftBlock and 1) == 0:
      if leftQuery.rightBlock < rightQuery.rightBlock:
        return -1
      return 1
    if leftQuery.rightBlock > rightQuery.rightBlock:
      return -1
    return 1
  if leftQuery.timeIndex != rightQuery.timeIndex:
    if (leftQuery.leftBlock and 1) == 0:
      if leftQuery.timeIndex < rightQuery.timeIndex:
        return -1
      return 1
    if leftQuery.timeIndex > rightQuery.timeIndex:
      return -1
    return 1
  return 0

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

let problemCount = nextInt(inputData, scanPos)
var currentValues = newSeq[int](problemCount + 1)
var initialValues = newSeq[int](problemCount + 1)
var maxDifficulty = 0
for position in 1 .. problemCount:
  currentValues[position] = nextInt(inputData, scanPos)
  initialValues[position] = currentValues[position]
  if currentValues[position] > maxDifficulty:
    maxDifficulty = currentValues[position]
var angerValues = newSeq[int](problemCount + 1)
for position in 1 .. problemCount:
  angerValues[position] = nextInt(inputData, scanPos)
let operationCount = nextInt(inputData, scanPos)

var queryRecords = newSeq[QueryRecord]()
var modificationPositions = newSeq[int]()
var modificationOldValues = newSeq[int]()
var modificationNewValues = newSeq[int]()
modificationPositions.add 0
modificationOldValues.add 0
modificationNewValues.add 0
var updateCount = 0
for operationIndex in 0 .. operationCount - 1:
  let operationType = nextInt(inputData, scanPos)
  let firstValue = nextInt(inputData, scanPos)
  let secondValue = nextInt(inputData, scanPos)
  if operationType == 1:
    queryRecords.add QueryRecord(leftEnd: firstValue, rightEnd: secondValue, timeIndex: updateCount,
                                 answerIndex: queryRecords.len, leftBlock: 0, rightBlock: 0)
  else:
    updateCount += 1
    modificationPositions.add firstValue
    modificationOldValues.add currentValues[firstValue]
    modificationNewValues.add secondValue
    currentValues[firstValue] = secondValue
    if secondValue > maxDifficulty:
      maxDifficulty = secondValue

var workValues = newSeq[int](problemCount + 1)
for position in 1 .. problemCount:
  workValues[position] = initialValues[position]

let blockWidth = 3000
for queryIndex in 0 .. queryRecords.len - 1:
  queryRecords[queryIndex].leftBlock = (queryRecords[queryIndex].leftEnd - 1) div blockWidth
  queryRecords[queryIndex].rightBlock = (queryRecords[queryIndex].rightEnd - 1) div blockWidth
queryRecords.sort(compareQueryRecords)

var occurrenceCounts = newSeq[int](maxDifficulty + 1)
var activeSum: int64 = 0
var activeLeft = 1
var activeRight = 0
var activeTime = 0

proc addPosition(position: int) =
  let difficulty = workValues[position]
  occurrenceCounts[difficulty] += 1
  activeSum = activeSum + int64(difficulty) * int64(angerValues[occurrenceCounts[difficulty]])

proc removePosition(position: int) =
  let difficulty = workValues[position]
  occurrenceCounts[difficulty] -= 1
  activeSum = activeSum - int64(difficulty) * int64(angerValues[occurrenceCounts[difficulty] + 1])

proc applyModification(timeIndex: int) =
  let position = modificationPositions[timeIndex]
  let replacement = modificationNewValues[timeIndex]
  if position >= activeLeft and position <= activeRight:
    removePosition(position)
    workValues[position] = replacement
    addPosition(position)
  else:
    workValues[position] = replacement

proc revertModification(timeIndex: int) =
  let position = modificationPositions[timeIndex]
  let previous = modificationOldValues[timeIndex]
  if position >= activeLeft and position <= activeRight:
    removePosition(position)
    workValues[position] = previous
    addPosition(position)
  else:
    workValues[position] = previous

var answerValues = newSeq[int64](queryRecords.len)
for queryRecord in queryRecords:
  while activeTime < queryRecord.timeIndex:
    activeTime += 1
    applyModification(activeTime)
  while activeTime > queryRecord.timeIndex:
    revertModification(activeTime)
    activeTime -= 1
  while activeLeft > queryRecord.leftEnd:
    activeLeft -= 1
    addPosition(activeLeft)
  while activeRight < queryRecord.rightEnd:
    activeRight += 1
    addPosition(activeRight)
  while activeLeft < queryRecord.leftEnd:
    removePosition(activeLeft)
    activeLeft += 1
  while activeRight > queryRecord.rightEnd:
    removePosition(activeRight)
    activeRight -= 1
  answerValues[queryRecord.answerIndex] = activeSum

for answerValue in answerValues:
  appendOutput($answerValue)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0

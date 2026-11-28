const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const unassigned = -1
const gridSpacingMeters: int64 = 200

proc nextLong(inputData: string, scanPos: var int): int64 =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  var negative = false
  if scanPos < inputData.len and inputData[scanPos] == '-':
    negative = true
    scanPos += 1
  var value: int64 = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int64(int(inputData[scanPos]) - firstDigitValue)
    scanPos += 1
  if negative:
    return -value
  return value

proc absLong(value: int64): int64 =
  if value < 0: -value else: value

var personU: seq[int64]
var personV: seq[int64]
var taxiU: seq[int64]
var taxiV: seq[int64]
var edgeTargets: seq[int]
var edgeStarts: seq[int]
var pairPerson: seq[int]
var pairTaxi: seq[int]
var distPerson: seq[int]
var queuePersons: seq[int]
var nilPersonIndex = 0

proc augment(personIdx: int): bool =
  for edgeIdx in edgeStarts[personIdx] ..< edgeStarts[personIdx + 1]:
    let taxiIdx = edgeTargets[edgeIdx]
    let matchedPerson = pairTaxi[taxiIdx]
    let nextPerson = if matchedPerson == unassigned: nilPersonIndex else: matchedPerson
    if distPerson[nextPerson] == distPerson[personIdx] + 1:
      if matchedPerson == unassigned or augment(matchedPerson):
        pairPerson[personIdx] = taxiIdx
        pairTaxi[taxiIdx] = personIdx
        return true
  distPerson[personIdx] = high(int)
  return false

proc searchLayers(): bool =
  var queueHead = 0
  var queueTail = 0
  for personIdx in 0 ..< nilPersonIndex:
    if pairPerson[personIdx] == unassigned:
      distPerson[personIdx] = 0
      queuePersons[queueTail] = personIdx
      queueTail += 1
    else:
      distPerson[personIdx] = high(int)
  distPerson[nilPersonIndex] = high(int)
  while queueHead < queueTail:
    let personIdx = queuePersons[queueHead]
    queueHead += 1
    if distPerson[personIdx] >= distPerson[nilPersonIndex]:
      continue
    for edgeIdx in edgeStarts[personIdx] ..< edgeStarts[personIdx + 1]:
      let taxiIdx = edgeTargets[edgeIdx]
      let matchedPerson = pairTaxi[taxiIdx]
      let nextPerson = if matchedPerson == unassigned: nilPersonIndex else: matchedPerson
      if distPerson[nextPerson] == high(int):
        distPerson[nextPerson] = distPerson[personIdx] + 1
        if matchedPerson != unassigned:
          queuePersons[queueTail] = matchedPerson
          queueTail += 1
  return distPerson[nilPersonIndex] != high(int)

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add "\n"

var scanPos = 0
let caseCount = int(nextLong(inputData, scanPos))
var outputBuffer = ""

for caseIdx in 0 ..< caseCount:
  let personCount = int(nextLong(inputData, scanPos))
  let taxiCount = int(nextLong(inputData, scanPos))
  let speedMetersPerSecond = nextLong(inputData, scanPos)
  let collectSeconds = nextLong(inputData, scanPos)
  let reachLimit = speedMetersPerSecond * collectSeconds

  personU.setLen(personCount)
  personV.setLen(personCount)
  for personIdx in 0 ..< personCount:
    let coordX = nextLong(inputData, scanPos)
    let coordY = nextLong(inputData, scanPos)
    personU[personIdx] = coordX + coordY
    personV[personIdx] = coordX - coordY

  taxiU.setLen(taxiCount)
  taxiV.setLen(taxiCount)
  for taxiIdx in 0 ..< taxiCount:
    let coordX = nextLong(inputData, scanPos)
    let coordY = nextLong(inputData, scanPos)
    taxiU[taxiIdx] = coordX + coordY
    taxiV[taxiIdx] = coordX - coordY

  edgeTargets.setLen(0)
  edgeStarts.setLen(personCount + 1)
  edgeStarts[0] = 0
  for personIdx in 0 ..< personCount:
    for taxiIdx in 0 ..< taxiCount:
      let deltaU = absLong(personU[personIdx] - taxiU[taxiIdx])
      let deltaV = absLong(personV[personIdx] - taxiV[taxiIdx])
      let walkingDistance = if deltaU > deltaV: deltaU else: deltaV
      if gridSpacingMeters * walkingDistance <= reachLimit:
        edgeTargets.add taxiIdx
    edgeStarts[personIdx + 1] = edgeTargets.len

  nilPersonIndex = personCount
  pairPerson.setLen(personCount)
  pairTaxi.setLen(taxiCount)
  distPerson.setLen(personCount + 1)
  queuePersons.setLen(personCount)
  for personIdx in 0 ..< personCount:
    pairPerson[personIdx] = unassigned
  for taxiIdx in 0 ..< taxiCount:
    pairTaxi[taxiIdx] = unassigned

  while searchLayers():
    for personIdx in 0 ..< nilPersonIndex:
      if pairPerson[personIdx] == unassigned:
        discard augment(personIdx)

  var matchedCount = 0
  for personIdx in 0 ..< nilPersonIndex:
    if pairPerson[personIdx] != unassigned:
      matchedCount += 1

  outputBuffer.add $matchedCount
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer

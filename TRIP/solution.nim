import std/algorithm

type
  TripTable = ref object
    aliceRoute: string
    bobRoute: string
    aliceLength: int
    bobLength: int
    rowWidth: int
    lengthTable: seq[int]
    isReady: seq[bool]
    answerTable: seq[seq[string]]

proc compareText(leftText, rightText: string): int =
  if leftText < rightText:
    return -1
  if leftText > rightText:
    return 1
  return 0

proc collectTrips(table: TripTable, leftIndex, rightIndex: int): seq[string] =
  if leftIndex == table.aliceLength or rightIndex == table.bobLength:
    return @[""]
  let stateIndex = leftIndex * table.rowWidth + rightIndex
  if table.isReady[stateIndex]:
    return table.answerTable[stateIndex]
  let bestLength = table.lengthTable[stateIndex]
  var collected: seq[string] = @[]
  if table.aliceRoute[leftIndex] == table.bobRoute[rightIndex] and
      bestLength == 1 + table.lengthTable[(leftIndex + 1) * table.rowWidth + rightIndex + 1]:
    let lastCity = table.aliceRoute[leftIndex]
    let tailList = collectTrips(table, leftIndex + 1, rightIndex + 1)
    for tailText in tailList:
      collected.add lastCity & tailText
  if bestLength == table.lengthTable[(leftIndex + 1) * table.rowWidth + rightIndex]:
    let tailList = collectTrips(table, leftIndex + 1, rightIndex)
    for tailText in tailList:
      collected.add tailText
  if bestLength == table.lengthTable[leftIndex * table.rowWidth + rightIndex + 1]:
    let tailList = collectTrips(table, leftIndex, rightIndex + 1)
    for tailText in tailList:
      collected.add tailText
  sort(collected, compareText)
  var uniqueCount = 0
  for position in 0 .. collected.len - 1:
    if position == 0 or collected[position] != collected[position - 1]:
      collected[uniqueCount] = collected[position]
      uniqueCount += 1
  collected.setLen(uniqueCount)
  table.isReady[stateIndex] = true
  table.answerTable[stateIndex] = collected
  return collected

proc buildTripTable(aliceRoute, bobRoute: string): TripTable =
  let table = new(TripTable)
  table.aliceRoute = aliceRoute
  table.bobRoute = bobRoute
  table.aliceLength = aliceRoute.len
  table.bobLength = bobRoute.len
  table.rowWidth = table.bobLength + 1
  let stateCount = (table.aliceLength + 1) * table.rowWidth
  table.lengthTable = newSeq[int](stateCount)
  table.isReady = newSeq[bool](stateCount)
  table.answerTable = newSeq[seq[string]](stateCount)
  for leftIndex in countdown(table.aliceLength - 1, 0):
    for rightIndex in countdown(table.bobLength - 1, 0):
      let stateIndex = leftIndex * table.rowWidth + rightIndex
      if table.aliceRoute[leftIndex] == table.bobRoute[rightIndex]:
        table.lengthTable[stateIndex] =
          1 + table.lengthTable[(leftIndex + 1) * table.rowWidth + rightIndex + 1]
      else:
        let skipAlice = table.lengthTable[(leftIndex + 1) * table.rowWidth + rightIndex]
        let skipBob = table.lengthTable[leftIndex * table.rowWidth + rightIndex + 1]
        table.lengthTable[stateIndex] = max(skipAlice, skipBob)
  return table

proc nextToken(inputData: string, scanPos: var int): string =
  let dataLength = inputData.len
  while scanPos < dataLength and inputData[scanPos] <= ' ':
    scanPos += 1
  let tokenStart = scanPos
  while scanPos < dataLength and inputData[scanPos] > ' ':
    scanPos += 1
  result = inputData[tokenStart .. scanPos - 1]

proc nextInteger(inputData: string, scanPos: var int): int =
  let numberText = nextToken(inputData, scanPos)
  var numberValue = 0
  for digitChar in numberText:
    numberValue = numberValue * 10 + (int(digitChar) - 48)
  return numberValue

const flushBlockBytes = 1 shl 18

proc appendOutput(outputBuffer: var string, text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
var scanPos = 0
let testCount = nextInteger(inputData, scanPos)
var outputBuffer = ""
for caseNumber in 0 .. testCount - 1:
  let aliceRoute = nextToken(inputData, scanPos)
  let bobRoute = nextToken(inputData, scanPos)
  let tripTable = buildTripTable(aliceRoute, bobRoute)
  let tripList = collectTrips(tripTable, 0, 0)
  if caseNumber > 0:
    appendOutput(outputBuffer, "\n")
  for tripText in tripList:
    appendOutput(outputBuffer, tripText)
    appendOutput(outputBuffer, "\n")
stdout.write outputBuffer

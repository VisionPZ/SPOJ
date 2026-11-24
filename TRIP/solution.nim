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

proc collectTrips(table: TripTable, i, j: int): seq[string] =
  if i == table.aliceLength or j == table.bobLength:
    return @[""]
  let k = i * table.rowWidth + j
  if table.isReady[k]:
    return table.answerTable[k]
  let bestLength = table.lengthTable[k]
  var collected: seq[string] = @[]
  if table.aliceRoute[i] == table.bobRoute[j] and
      bestLength == 1 + table.lengthTable[(i + 1) * table.rowWidth + j + 1]:
    let lastCity = table.aliceRoute[i]
    let tailList = collectTrips(table, i + 1, j + 1)
    for tailText in tailList:
      collected.add lastCity & tailText
  if bestLength == table.lengthTable[(i + 1) * table.rowWidth + j]:
    let tailList = collectTrips(table, i + 1, j)
    for tailText in tailList:
      collected.add tailText
  if bestLength == table.lengthTable[i * table.rowWidth + j + 1]:
    let tailList = collectTrips(table, i, j + 1)
    for tailText in tailList:
      collected.add tailText
  sort(collected, compareText)
  var uniqueCount = 0
  for l in 0 .. collected.len - 1:
    if l == 0 or collected[l] != collected[l - 1]:
      collected[uniqueCount] = collected[l]
      uniqueCount += 1
  collected.setLen(uniqueCount)
  table.isReady[k] = true
  table.answerTable[k] = collected
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
  for i in countdown(table.aliceLength - 1, 0):
    for j in countdown(table.bobLength - 1, 0):
      let k = i * table.rowWidth + j
      if table.aliceRoute[i] == table.bobRoute[j]:
        table.lengthTable[k] =
          1 + table.lengthTable[(i + 1) * table.rowWidth + j + 1]
      else:
        let skipAlice = table.lengthTable[(i + 1) * table.rowWidth + j]
        let skipBob = table.lengthTable[i * table.rowWidth + j + 1]
        table.lengthTable[k] = max(skipAlice, skipBob)
  return table

proc nextToken(inputData: string, i: var int): string =
  let dataLength = inputData.len
  while i < dataLength and inputData[i] <= ' ':
    i += 1
  let j = i
  while i < dataLength and inputData[i] > ' ':
    i += 1
  result = inputData[j .. i - 1]

proc nextInteger(inputData: string, i: var int): int =
  let numberText = nextToken(inputData, i)
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
var i = 0
let testCount = nextInteger(inputData, i)
var outputBuffer = ""
for j in 0 .. testCount - 1:
  let aliceRoute = nextToken(inputData, i)
  let bobRoute = nextToken(inputData, i)
  let tripTable = buildTripTable(aliceRoute, bobRoute)
  let tripList = collectTrips(tripTable, 0, 0)
  if j > 0:
    appendOutput(outputBuffer, "\n")
  for tripText in tripList:
    appendOutput(outputBuffer, tripText)
    appendOutput(outputBuffer, "\n")
stdout.write outputBuffer

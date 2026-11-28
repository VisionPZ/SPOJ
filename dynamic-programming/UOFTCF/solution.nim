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

proc nextGridRow(data: string, pos: var int, columnCount: int): string =
  while pos < data.len and data[pos] != '.' and data[pos] != '#':
    pos += 1
  var collected = 0
  while collected < columnCount and pos < data.len:
    if data[pos] == '.' or data[pos] == '#':
      result.add data[pos]
      collected += 1
    pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let sidewalkCount = nextInt(inputData, scanPos)
for sidewalkIndex in 0 .. sidewalkCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  var gridRows = newSeq[string](rowCount)
  for rowIndex in 0 .. rowCount - 1:
    gridRows[rowIndex] = nextGridRow(inputData, scanPos, columnCount)
  let stateSize = columnCount * columnCount
  var previousScores = newSeq[int](stateSize)
  var currentScores = newSeq[int](stateSize)
  for stateIndex in 0 .. stateSize - 1:
    previousScores[stateIndex] = -1
  for aliceColumn in 0 .. columnCount - 1:
    if gridRows[0][aliceColumn] != '.':
      continue
    for bobColumn in 0 .. columnCount - 1:
      if aliceColumn == bobColumn or gridRows[0][bobColumn] != '.':
        continue
      let gap = aliceColumn - bobColumn
      let startScore = if gap == 1 or gap == -1: 1 else: 0
      previousScores[aliceColumn * columnCount + bobColumn] = startScore
  for rowIndex in 1 .. rowCount - 1:
    for stateIndex in 0 .. stateSize - 1:
      currentScores[stateIndex] = -1
    for aliceColumn in 0 .. columnCount - 1:
      for bobColumn in 0 .. columnCount - 1:
        let scoreHere = previousScores[aliceColumn * columnCount + bobColumn]
        if scoreHere < 0:
          continue
        for aliceStep in -1 .. 1:
          let nextAlice = aliceColumn + aliceStep
          if nextAlice < 0 or nextAlice >= columnCount:
            continue
          if gridRows[rowIndex][nextAlice] != '.':
            continue
          for bobStep in -1 .. 1:
            let nextBob = bobColumn + bobStep
            if nextBob < 0 or nextBob >= columnCount:
              continue
            if gridRows[rowIndex][nextBob] != '.' or nextAlice == nextBob:
              continue
            let gap = nextAlice - nextBob
            let addedScore = if gap == 1 or gap == -1: 1 else: 0
            let targetIndex = nextAlice * columnCount + nextBob
            let candidateScore = scoreHere + addedScore
            if candidateScore > currentScores[targetIndex]:
              currentScores[targetIndex] = candidateScore
    swap(previousScores, currentScores)
  var bestScore = -1
  for stateIndex in 0 .. stateSize - 1:
    if previousScores[stateIndex] > bestScore:
      bestScore = previousScores[stateIndex]
  if bestScore < 0:
    appendOutput("Detour\n")
  else:
    appendOutput($bestScore)
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

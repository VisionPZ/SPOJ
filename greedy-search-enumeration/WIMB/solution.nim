const flushBlockBytes = 1 shl 17
const gamesInSetWin = 6
const setsInMatchWin = 3
const minutesPerGame = 5
const decimalScale = 1000000
const memoSize = 2048

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

var firstServeProbability = 0.0
var secondServeProbability = 0.0
var memoizedGames: array[0 .. memoSize - 1, float64]

proc applyGame(firstGames, secondGames, firstSets, secondSets: int, firstWon: bool,
               nextFirstGames, nextSecondGames, nextFirstSets, nextSecondSets: var int) =
  if firstWon:
    nextFirstGames = firstGames + 1
    nextSecondGames = secondGames
  else:
    nextFirstGames = firstGames
    nextSecondGames = secondGames + 1
  var setFinished = false
  nextFirstSets = firstSets
  nextSecondSets = secondSets
  if nextFirstGames >= gamesInSetWin and nextFirstGames - nextSecondGames >= 2:
    nextFirstSets = firstSets + 1
    setFinished = true
  elif nextSecondGames >= gamesInSetWin and nextSecondGames - nextFirstGames >= 2:
    nextSecondSets = secondSets + 1
    setFinished = true
  elif nextFirstGames == gamesInSetWin + 1 and nextSecondGames == gamesInSetWin:
    nextFirstSets = firstSets + 1
    setFinished = true
  elif nextSecondGames == gamesInSetWin + 1 and nextFirstGames == gamesInSetWin:
    nextSecondSets = secondSets + 1
    setFinished = true
  if setFinished:
    nextFirstGames = 0
    nextSecondGames = 0

proc expectedGames(firstGames, secondGames, firstSets, secondSets, server: int): float64 =
  if firstSets == setsInMatchWin or secondSets == setsInMatchWin:
    return 0.0
  let stateIndex = (((firstGames * 8 + secondGames) * 4 + firstSets) * 4 + secondSets) * 2 + server
  if memoizedGames[stateIndex] >= 0.0:
    return memoizedGames[stateIndex]
  var winProbability = firstServeProbability
  if server == 1:
    winProbability = 1.0 - secondServeProbability
  var winFirstGames, winSecondGames, winFirstSets, winSecondSets: int
  applyGame(firstGames, secondGames, firstSets, secondSets, true,
            winFirstGames, winSecondGames, winFirstSets, winSecondSets)
  var loseFirstGames, loseSecondGames, loseFirstSets, loseSecondSets: int
  applyGame(firstGames, secondGames, firstSets, secondSets, false,
            loseFirstGames, loseSecondGames, loseFirstSets, loseSecondSets)
  let nextServer = 1 - server
  let expected = 1.0 +
    winProbability * expectedGames(winFirstGames, winSecondGames, winFirstSets, winSecondSets, nextServer) +
    (1.0 - winProbability) * expectedGames(loseFirstGames, loseSecondGames, loseFirstSets, loseSecondSets, nextServer)
  memoizedGames[stateIndex] = expected
  return expected

proc formatMinutes(minutes: float64): string =
  let scaled = int64(minutes * float64(decimalScale) + 0.5)
  var whole = scaled div decimalScale
  var fraction = scaled mod decimalScale
  if fraction == decimalScale:
    whole += 1
    fraction = 0
  result = $whole
  result.add '.'
  var divisor: int64 = decimalScale div 10
  while divisor > 0:
    result.add chr(48 + int(fraction div divisor))
    fraction = fraction mod divisor
    divisor = divisor div 10
  result.add '\n'

for stateIndex in 0 .. memoSize - 1:
  memoizedGames[stateIndex] = -1.0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let firstServePercent = nextInt(inputData, scanPos)
  let secondServePercent = nextInt(inputData, scanPos)
  firstServeProbability = float64(firstServePercent) / 100.0
  secondServeProbability = float64(secondServePercent) / 100.0
  for stateIndex in 0 .. memoSize - 1:
    memoizedGames[stateIndex] = -1.0
  let matchMinutes = expectedGames(0, 0, 0, 0, 0) * float64(minutesPerGame)
  appendOutput(formatMinutes(matchMinutes))
stdout.write outputBuffer
outputBuffer.setLen 0

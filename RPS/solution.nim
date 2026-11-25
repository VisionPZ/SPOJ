const flushBlockBytes = 1 shl 17
const maxPlayers = 20

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

var turnTable = newSeq[seq[int]](maxPlayers + 1)
for playerIndex in 0 .. maxPlayers:
  turnTable[playerIndex] = newSeq[int](maxPlayers + 1)

for playerCount in 2 .. maxPlayers:
  var counts = newSeq[int](playerCount + 2)
  counts[0] = playerCount
  var turnNumber = 0
  var missingTargets = playerCount - 1
  while missingTargets > 0:
    turnNumber += 1
    var nextCounts = newSeq[int](counts.len)
    var gamesPlayed = 0
    for winLevel in 0 .. counts.len - 1:
      gamesPlayed += counts[winLevel] div 2
    nextCounts[0] = counts[0] mod 2 + gamesPlayed
    for winLevel in 1 .. counts.len - 1:
      nextCounts[winLevel] = counts[winLevel] mod 2 + counts[winLevel - 1] div 2
    counts = nextCounts
    for targetWins in 1 .. playerCount - 1:
      if turnTable[playerCount][targetWins] == 0 and counts[targetWins] > 0:
        turnTable[playerCount][targetWins] = turnNumber
        missingTargets -= 1

var caseNumber = 0
while true:
  let playerCount = nextInt(inputData, scanPos)
  let targetWins = nextInt(inputData, scanPos)
  if playerCount == 0 and targetWins == 0:
    break
  caseNumber += 1
  appendOutput("Case " & $caseNumber & ": " & $turnTable[playerCount][targetWins])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

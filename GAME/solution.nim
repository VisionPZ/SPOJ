import tables

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ': pos += 1
  let startPos = pos
  while pos < data.len and data[pos] > ' ': pos += 1
  return data[startPos ..< pos]

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'): pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  var teamCount = nextInt(inputData, scanPos)
  if teamCount == 0: break
  var teamNames: seq[string]
  teamNames.setLen(teamCount)
  var nameToIndex = initTable[string, int]()
  for teamIndex in 0 ..< teamCount:
    let teamName = nextToken(inputData, scanPos)
    teamNames[teamIndex] = teamName
    nameToIndex[teamName] = teamIndex
  var adjacency: seq[seq[int]]
  adjacency.setLen(teamCount)
  for teamIndex in 0 ..< teamCount:
    adjacency[teamIndex] = @[]
  for gameIndex in 0 ..< (teamCount - 1):
    let firstName = nextToken(inputData, scanPos)
    let secondName = nextToken(inputData, scanPos)
    let firstIndex = nameToIndex[firstName]
    let secondIndex = nameToIndex[secondName]
    adjacency[firstIndex].add secondIndex
    adjacency[secondIndex].add firstIndex
  var aliveTeams: seq[bool]
  aliveTeams.setLen(teamCount)
  for teamIndex in 0 ..< teamCount:
    aliveTeams[teamIndex] = true
  var remainingCount = teamCount
  var roundNumber = 1
  while remainingCount > 1:
    let neededGames = remainingCount div 2
    let hadWildcard = (remainingCount mod 2) == 1
    var usedWinner: seq[bool]
    usedWinner.setLen(teamCount)
    for teamIndex in 0 ..< teamCount:
      usedWinner[teamIndex] = false
    var chosenLosers: seq[int]
    var chosenWinners: seq[int]
    for teamIndex in 0 ..< teamCount:
      if chosenLosers.len == neededGames: break
      if not aliveTeams[teamIndex]: continue
      var aliveNeighborCount = 0
      var neighborWinner = -1
      for neighborIndex in adjacency[teamIndex]:
        if aliveTeams[neighborIndex]:
          aliveNeighborCount += 1
          neighborWinner = neighborIndex
      if aliveNeighborCount == 1 and not usedWinner[neighborWinner]:
        chosenLosers.add teamIndex
        chosenWinners.add neighborWinner
        usedWinner[neighborWinner] = true
    appendOutput("Round #")
    appendOutput($roundNumber)
    appendOutput("\n")
    for choiceIndex in 0 ..< chosenLosers.len:
      appendOutput(teamNames[chosenWinners[choiceIndex]])
      appendOutput(" defeats ")
      appendOutput(teamNames[chosenLosers[choiceIndex]])
      appendOutput("\n")
    for loserIndex in chosenLosers:
      aliveTeams[loserIndex] = false
    remainingCount = remainingCount - chosenLosers.len
    if hadWildcard:
      for teamIndex in 0 ..< teamCount:
        if aliveTeams[teamIndex] and not usedWinner[teamIndex]:
          appendOutput(teamNames[teamIndex])
          appendOutput(" advances with wildcard\n")
          break
    roundNumber += 1
  for teamIndex in 0 ..< teamCount:
    if aliveTeams[teamIndex]:
      appendOutput("Winner: ")
      appendOutput(teamNames[teamIndex])
      appendOutput("\n")
      break
  appendOutput("\n")

stdout.write outputBuffer

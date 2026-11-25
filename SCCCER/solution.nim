const flushBlockBytes = 1 shl 17
const teamKinds = 4
const lastKinds = 5
const runKinds = 3
const impossibleCost = 1000000000

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

proc nextTeamWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] notin {'C', 'P', 'N', 'S'}:
    pos += 1
  var word = ""
  while pos < data.len and data[pos] in {'C', 'P', 'N', 'S'}:
    word.add data[pos]
    pos += 1
  return word

proc teamNumber(letter: char): int =
  case letter
  of 'C':
    return 0
  of 'P':
    return 1
  of 'N':
    return 2
  else:
    return 3

proc encodeState(countZero, countOne, countTwo, lastTeam, runLength, countBase: int): int =
  return (((countZero * countBase + countOne) * countBase + countTwo) * lastKinds + lastTeam) * runKinds + runLength

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseNumber in 0 .. caseCount - 1:
  let playerCount = nextInt(inputData, scanPos)
  let seatTeams = nextTeamWord(inputData, scanPos)
  var totalCounts = [0, 0, 0, 0]
  for seatIndex in 0 .. playerCount - 1:
    totalCounts[teamNumber(seatTeams[seatIndex])] += 1
  let countBase = playerCount + 1
  let countSquare = countBase * countBase
  let stateBase = countSquare * countBase
  let stateCount = stateBase * lastKinds * runKinds
  var currentCosts = newSeq[int](stateCount)
  var nextCosts = newSeq[int](stateCount)
  var activeStates: seq[int] = @[]
  var nextStates: seq[int] = @[]
  for stateIndex in 0 .. stateCount - 1:
    currentCosts[stateIndex] = impossibleCost
    nextCosts[stateIndex] = impossibleCost
  let initialState = encodeState(0, 0, 0, teamKinds, 0, countBase)
  currentCosts[initialState] = 0
  activeStates.add initialState
  for seatIndex in 0 .. playerCount - 1:
    nextStates.setLen 0
    for stateIndex in activeStates:
      let stateCost = currentCosts[stateIndex]
      let runLength = stateIndex mod runKinds
      let afterRun = stateIndex div runKinds
      let lastTeam = afterRun mod lastKinds
      let afterLast = afterRun div lastKinds
      let countTwo = afterLast mod countBase
      let afterTwo = afterLast div countBase
      let countOne = afterTwo mod countBase
      let countZero = afterTwo div countBase
      let countThree = seatIndex - countZero - countOne - countTwo
      var usedCounts = [countZero, countOne, countTwo, countThree]
      let wantedTeam = teamNumber(seatTeams[seatIndex])
      for chosenTeam in 0 .. teamKinds - 1:
        if usedCounts[chosenTeam] >= totalCounts[chosenTeam]:
          continue
        var nextRun = 1
        if chosenTeam == lastTeam:
          nextRun = runLength + 1
        if nextRun > 2:
          continue
        var newZero = countZero
        var newOne = countOne
        var newTwo = countTwo
        case chosenTeam
        of 0:
          newZero += 1
        of 1:
          newOne += 1
        of 2:
          newTwo += 1
        else:
          discard
        let newState = encodeState(newZero, newOne, newTwo, chosenTeam, nextRun, countBase)
        var newCost = stateCost
        if chosenTeam != wantedTeam:
          newCost += 1
        if newCost < nextCosts[newState]:
          if nextCosts[newState] == impossibleCost:
            nextStates.add newState
          nextCosts[newState] = newCost
    for stateIndex in activeStates:
      currentCosts[stateIndex] = impossibleCost
    let swapCosts = currentCosts
    currentCosts = nextCosts
    nextCosts = swapCosts
    activeStates = nextStates
  var bestCost = impossibleCost
  for stateIndex in activeStates:
    let afterRun = stateIndex div runKinds
    let afterLast = afterRun div lastKinds
    let countTwo = afterLast mod countBase
    let afterTwo = afterLast div countBase
    let countOne = afterTwo mod countBase
    let countZero = afterTwo div countBase
    if countZero == totalCounts[0] and countOne == totalCounts[1] and countTwo == totalCounts[2]:
      if currentCosts[stateIndex] < bestCost:
        bestCost = currentCosts[stateIndex]
  if bestCost == impossibleCost:
    appendOutput("-1")
  else:
    appendOutput($bestCost)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

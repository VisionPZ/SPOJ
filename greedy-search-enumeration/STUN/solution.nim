const flushBlockBytes = 1 shl 17
const roundSeconds = 240
const stunSeconds = 7
const stunReward = 300
const poisonReward = 1800
const poisonMinimum = 2
const playerCount = 6
const teamCount = 3
const groupCount = 2
const maximumEvents = 80

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

while true:
  let goalExperience = nextInt(inputData, scanPos)
  let roundTotal = nextInt(inputData, scanPos)
  if goalExperience == 0 and roundTotal == 0:
    break
  var playerExperience = newSeq[int](playerCount)
  for playerIndex in 0 .. playerCount - 1:
    playerExperience[playerIndex] = nextInt(inputData, scanPos)
  var winnerIdentifier = 0
  var winnerRound = 0
  for playerIndex in 0 .. playerCount - 1:
    if playerExperience[playerIndex] >= goalExperience:
      winnerIdentifier = playerIndex + 1
      break
  for roundNumber in 1 .. roundTotal:
    var arrivalTimes = newSeq[int](playerCount)
    for playerIndex in 0 .. playerCount - 1:
      arrivalTimes[playerIndex] = nextInt(inputData, scanPos)
    if winnerIdentifier != 0:
      continue
    var groupMembers = newSeq[seq[int]]()
    for groupIndex in 0 .. groupCount - 1:
      groupMembers.add newSeq[int](teamCount)
    for teamIndex in 0 .. teamCount - 1:
      let lowerPlayer = teamIndex * 2
      let higherPlayer = teamIndex * 2 + 1
      if arrivalTimes[lowerPlayer] <= arrivalTimes[higherPlayer]:
        groupMembers[0][teamIndex] = lowerPlayer
        groupMembers[1][teamIndex] = higherPlayer
      else:
        groupMembers[0][teamIndex] = higherPlayer
        groupMembers[1][teamIndex] = lowerPlayer
    var groupStarts = newSeq[int](groupCount)
    for groupIndex in 0 .. groupCount - 1:
      var latestArrival = 0
      for memberIndex in 0 .. teamCount - 1:
        let playerIndex = groupMembers[groupIndex][memberIndex]
        if arrivalTimes[playerIndex] > latestArrival:
          latestArrival = arrivalTimes[playerIndex]
      groupStarts[groupIndex] = latestArrival
    var eventTimes = newSeq[int](maximumEvents)
    var eventGroups = newSeq[int](maximumEvents)
    var eventRewards = newSeq[int](maximumEvents)
    var eventCount = 0
    for groupIndex in 0 .. groupCount - 1:
      let startSecond = groupStarts[groupIndex]
      let stunRounds = (roundSeconds - startSecond) div stunSeconds
      for stunIndex in 1 .. stunRounds:
        eventTimes[eventCount] = startSecond + stunIndex * stunSeconds
        eventGroups[eventCount] = groupIndex
        eventRewards[eventCount] = stunReward
        eventCount += 1
      let remainingSeconds = roundSeconds - startSecond - stunRounds * stunSeconds
      if remainingSeconds >= poisonMinimum:
        eventTimes[eventCount] = roundSeconds
        eventGroups[eventCount] = groupIndex
        eventRewards[eventCount] = poisonReward
        eventCount += 1
    for eventIndex in 1 .. eventCount - 1:
      let heldTime = eventTimes[eventIndex]
      let heldGroup = eventGroups[eventIndex]
      let heldReward = eventRewards[eventIndex]
      var previousIndex = eventIndex - 1
      while previousIndex >= 0 and eventTimes[previousIndex] > heldTime:
        eventTimes[previousIndex + 1] = eventTimes[previousIndex]
        eventGroups[previousIndex + 1] = eventGroups[previousIndex]
        eventRewards[previousIndex + 1] = eventRewards[previousIndex]
        previousIndex -= 1
      eventTimes[previousIndex + 1] = heldTime
      eventGroups[previousIndex + 1] = heldGroup
      eventRewards[previousIndex + 1] = heldReward
    var eventIndex = 0
    while eventIndex < eventCount:
      let currentSecond = eventTimes[eventIndex]
      while eventIndex < eventCount and eventTimes[eventIndex] == currentSecond:
        let groupIndex = eventGroups[eventIndex]
        let rewardValue = eventRewards[eventIndex]
        for memberIndex in 0 .. teamCount - 1:
          let playerIndex = groupMembers[groupIndex][memberIndex]
          playerExperience[playerIndex] += rewardValue
        eventIndex += 1
      for playerIndex in 0 .. playerCount - 1:
        if playerExperience[playerIndex] >= goalExperience:
          if winnerIdentifier == 0 or playerIndex + 1 < winnerIdentifier:
            winnerIdentifier = playerIndex + 1
          break
      if winnerIdentifier != 0:
        winnerRound = roundNumber
        break
  if winnerIdentifier != 0:
    appendOutput($winnerIdentifier)
    outputBuffer.add ' '
    appendOutput($winnerRound)
    outputBuffer.add '\n'
  else:
    appendOutput("-1")
    for playerIndex in 0 .. playerCount - 1:
      outputBuffer.add ' '
      appendOutput($playerExperience[playerIndex])
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0

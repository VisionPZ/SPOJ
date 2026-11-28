# STUN — Stun Boosting (SPOJ)

<https://www.spoj.com/problems/STUN/>

## Problem

Six players in three teams farm experience by stunning each other in four-minute rounds. Each round forms two groups of three from the teams, and a group starts when its last member reaches the map center. Stun rounds grant experience every seven seconds, and poison grants a larger bonus at the end when enough time remains. Report the first player to reach the goal, or the final experience of all six.

Each test case gives the goal and round count, six starting experience values, then six arrival times per round. A case with goal zero and round count zero ends the input. Print the winner's identifier and round number, or `-1` followed by six experience totals.

| item | bound |
|---|---|
| goal experience | 1 to 650000 |
| rounds | 1 to 1000 |
| arrival time | 1 to 239 seconds |
| round length | 240 seconds |
| stun reward | 300 per seven seconds |
| poison reward | 1800 at second 240 |
| judge limit | 1000 ms, 1536 MB |

Starting experience already at or above the goal wins in round zero.

Sample input:

```
10000 1
1000 12345 50000 9000 100 1
30 10 20 20 10 30
650000 1
100 200 300 400 500 600
20 10 30 20 20 30
0 0
```

Sample output:

```
2 0
-1 9100 11300 9300 11500 11600 9600
```

## Idea

Treat every award as a dated event, like entries on a calendar, then scan the events in time order. A group produces one event per completed stun round and one poison event when two or more seconds remain. Sorting a short event list finds the first crossing of the goal without stepping through every second. Replaying each round second by second would do more work, so batching equal timestamps keeps the check tight.

## Why It Works

1. Each team sends its earliest arrival to the first group, with the lower identifier winning a tie.
2. A group starts when its slowest member arrives.
3. Stun rounds finish at start plus 7, plus 14, and so on, up to second 240.
4. Poison is awarded at second 240 when at least two seconds remain after the last stun.
5. All awards at one second are applied before checking the goal, and the lowest identifier wins ties.

| term | meaning |
|---|---|
| `groupMembers` | the three players in each boosting group |
| `groupStarts` | latest arrival second for each group |
| `eventTimes` | seconds when rewards are granted |
| `eventRewards` | experience granted by each event |
| `winnerRound` | round in which the goal was first reached |

Each event belongs to one group and one second.

Script-generated trace for the second sample case:

```
quantity | value
group one | players 2, 4, 5
group one start | max(10, 20, 20) = 20
group one stuns | (240 - 20) / 7 = 31
group one leftover | 240 - 20 - 217 = 3
group one xp | 31 * 300 + 1800 = 11100
group two | players 1, 3, 6
group two start | max(20, 30, 30) = 30
group two stuns | (240 - 30) / 7 = 30
group two leftover | 0
group two xp | 30 * 300 = 9000
```

No player reaches 650000, so the six final totals are printed.

## Code

**Bulk input and buffered output.** All numbers come from one string, and answers leave in blocks.

```nim
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
```

The constants mirror the rules of the game.
The scanner skips spaces and line breaks.
The buffer flushes once it reaches 128 KiB.

**Grouping and event replay.** Each round builds, sorts, and applies its reward events.

```nim
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
```

Ties inside a team favour the lower identifier.
Insertion sort handles at most 70 events per round.
All awards sharing a second are applied together.
The final branch writes either a winner or six totals.

## Complexity

Each round generates at most 34 stun events per group and one poison event.

| phase | time | space |
|---|---|---|
| input read | one pass over all arrival times | one input string |
| event build | one entry per stun round and poison | three short arrays |
| event sort | at most 64 entries per round | block buffer |
| output | one line per test case | block buffer |

The event count stays bounded no matter how many rounds are played.

| measure | Big O |
|---|---|
| time per round | O(events log events) |
| time per case | O(rounds times events log events) |
| space per case | O(events) |

Stepping through 240 seconds for every round would repeat empty checks.

The event list keeps the simulation focused on award moments.

# MMINPAID — Paid Roads (SPOJ)

<https://www.spoj.com/problems/MMINPAID/>

## Problem

Find the cheapest route from city 1 to city N. Each paid road can be settled before departure in a chosen city or on arrival in its end city.

The input holds one case. The first line gives the city count N and the road count m.

Each next line gives a_i, b_i, c_i, P_i, R_i for a directed road and its two payment options. Output the minimum route cost, or `impossible` when city N has no route from city 1.

| item | bound |
|---|---|
| cities N | 1 to 10 |
| roads m | 1 to 10 |
| prices P_i and R_i | 0 to 100, with P_i at most R_i |
| judge limit | 1000 ms, 1536 MB |

The advance payment happens in c_i, which need not equal a_i. The road becomes usable for free once that payment is made.

Sample input:

```
4 5
1 2 1 10 10
2 3 1 30 50
3 4 3 80 80
2 1 2 10 10
1 3 2 10 50
```

Sample output:

```
110
```

## Idea

Prepaying a road is like buying a ticket at a booth: once bought, the ride costs nothing later.

The algorithm is a shortest-path search over states made of a city and a prepaid-road mask. Each advance payment sets one bit and costs P_i. Each road traversal costs R_i unless its bit is set.

A search over cities alone forgets which tickets are held, so it can miss the cheapest route. Track tickets in a mask and relax every state through a queue.

## Why It Works

1. Road i leaves a_i, reaches b_i, and can be paid early in c_i for P_i.
2. An early payment needs the traveller to stand in c_i and sets bit i.
3. A prepaid road costs zero to travel; any other road costs R_i on arrival.
4. A state (city, mask) records the position and every ticket held there.
5. Queue relaxation reaches the least cost of every reachable state.

| term | meaning |
|---|---|
| `roadBit` | the mask bit for one road |
| `bestCosts` | least cost found for each (city, mask) state |
| `unreachableCost` | sentinel larger than any real route cost |
| `nextCost` | cost of a candidate transition |
| `answer` | least cost among all states in city N |

The terms above match the driver, so each transition maps to one table entry.

The sample script picks roads 1, 4, 5, then 3. Pay 10 to reach city 2, then prepay road 5 for 10 in city 2.

Pay 10 to return to city 1, ride road 5 free to city 3, and pay 80 for road 3. The total is 10 + 10 + 10 + 0 + 80 = 110.

The sentinel is safe because ten roads cost at most 1000 together. Queue relaxation visits a state again only after its cost drops.

## Code

**Input and scanning.** The reader loads the header and all five fields of every road.

```nim
const flushBlockBytes = 1 shl 17
const unreachableCost = 1000000000

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

City indexes start at zero after parsing.
The scanner skips spaces and line breaks.
The buffer flushes in large blocks.

**State relaxation and answer.** Every queued state tries both advance payments and road travel.

```nim
let cityCount = nextInt(inputData, scanPos)
let roadCount = nextInt(inputData, scanPos)
var roadStarts = newSeq[int](roadCount)
var roadEnds = newSeq[int](roadCount)
var roadPayCities = newSeq[int](roadCount)
var roadAdvancePrices = newSeq[int](roadCount)
var roadArrivalPrices = newSeq[int](roadCount)
for roadIndex in 0 .. roadCount - 1:
  roadStarts[roadIndex] = nextInt(inputData, scanPos) - 1
  roadEnds[roadIndex] = nextInt(inputData, scanPos) - 1
  roadPayCities[roadIndex] = nextInt(inputData, scanPos) - 1
  roadAdvancePrices[roadIndex] = nextInt(inputData, scanPos)
  roadArrivalPrices[roadIndex] = nextInt(inputData, scanPos)

let maskCount = 1 shl roadCount
let stateCount = cityCount * maskCount
var bestCosts = newSeq[int](stateCount)
for stateIndex in 0 .. stateCount - 1:
  bestCosts[stateIndex] = unreachableCost
bestCosts[0] = 0
var inQueue = newSeq[bool](stateCount)
var pendingStates = newSeq[int]()
pendingStates.add 0
inQueue[0] = true
var queueHead = 0

while queueHead < pendingStates.len:
  let stateIndex = pendingStates[queueHead]
  queueHead += 1
  inQueue[stateIndex] = false
  let currentCity = stateIndex div maskCount
  let currentMask = stateIndex mod maskCount
  let currentCost = bestCosts[stateIndex]
  for roadIndex in 0 .. roadCount - 1:
    let roadBit = 1 shl roadIndex
    if roadPayCities[roadIndex] == currentCity and (currentMask and roadBit) == 0:
      let nextMask = currentMask or roadBit
      let nextStateIndex = currentCity * maskCount + nextMask
      let nextCost = currentCost + roadAdvancePrices[roadIndex]
      if nextCost < bestCosts[nextStateIndex]:
        bestCosts[nextStateIndex] = nextCost
        if not inQueue[nextStateIndex]:
          pendingStates.add nextStateIndex
          inQueue[nextStateIndex] = true
    if roadStarts[roadIndex] == currentCity:
      var travelCost = roadArrivalPrices[roadIndex]
      if (currentMask and roadBit) != 0:
        travelCost = 0
      let nextStateIndex = roadEnds[roadIndex] * maskCount + currentMask
      let nextCost = currentCost + travelCost
      if nextCost < bestCosts[nextStateIndex]:
        bestCosts[nextStateIndex] = nextCost
        if not inQueue[nextStateIndex]:
          pendingStates.add nextStateIndex
          inQueue[nextStateIndex] = true

var answer = unreachableCost
for maskIndex in 0 .. maskCount - 1:
  let candidate = bestCosts[(cityCount - 1) * maskCount + maskIndex]
  if candidate < answer:
    answer = candidate
if answer >= unreachableCost:
  appendOutput("impossible\n")
else:
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Advance payments stay in the same city and flip one bit.
Travel moves to the road end and keeps the mask.
The final scan takes the cheapest state in city N.

## Complexity

The search runs once over the combined state space.

| phase | time | space |
|---|---|---|
| input read | one pass over m roads | five road arrays |
| state relaxation | up to two tries per road per state | one cost array and one queue |
| output | one line | block buffer |

The table shows that reading is cheap and relaxation does the work.

| measure | Big O |
|---|---|
| states | N times two to the m |
| time | O(N times m times two to the m) |
| space | O(N times two to the m) |

At the given limits the state count stays below ten thousand.
A route-only search over cities ignores prepaid tickets and can overcharge for a road.
Track the mask, and every payment choice is represented exactly once.

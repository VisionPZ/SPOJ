<https://www.spoj.com/problems/TRSTAGE/>

## Problem

Find the quickest stagecoach route between two cities when each ticket has a fixed number of horses and can be used once. Each ride crosses one road and consumes one ticket, and time equals road length divided by horses.

Input holds several datasets. A dataset starts with `n m p a b`: ticket count, city count, road count, start city, and target city. The next line lists `n` horse counts. Then `p` lines each give two city indices and a road length. Five zeros end the input. Print the best time with three decimals, or `Impossible`.

| item | bound |
|---|---|
| tickets | 1 to 8 |
| cities | 2 to 30 |
| road length | 1 to 100 |
| horses per ticket | 1 to 10 |
| judge limit | 1000 ms, 1536 MB |

Cities are numbered from one, roads are undirected, and no pair has two roads.

Sample input:

```
3 4 3 1 4
3 1 2
1 2 10
2 3 30
3 4 20
2 4 4 2 1
3 1
2 3 3
1 3 3
4 1 2
4 2 5
2 4 3 4 1
5 5
1 2 10
2 3 10
3 4 10
1 2 0 1 2
1
8 5 10 1 5
2 7 1 8 4 5 6 3
1 2 5
2 3 4
3 4 7
4 5 3
1 3 25
2 4 23
3 5 22
1 4 45
2 5 51
1 5 99
0 0 0 0 0
```

Sample output:

```
30.000
3.667
Impossible
Impossible
2.856
```

## Idea

Add one used ticket to the route description each time the coach moves, like ticking off coupons in a booklet. The coupon set and current city form a state, and states move only forward. Dynamic programming over these states keeps the best scaled time with no heap. All horse counts divide 2520, so integer arithmetic replaces fractions. The takeaway is that a small ticket count makes the state space tiny.

## Why It Works

1. The number 2520 is divisible by every horse count from one to ten.
2. A ride's scaled time is road length times 2520 divided by the ticket's horses.
3. Each transition sets one new ticket bit, so the state graph has no cycles.
4. Scanning masks in increasing order visits every reachable city and ticket set.
5. The smallest scaled time at the target is the optimal route.

| term | meaning |
|---|---|
| `timeScale` | common denominator 2520 |
| `ticketFactors` | scaled time per unit distance for each ticket |
| `bestTimes` | smallest scaled time for each mask and city |
| `bestAnswer` | smallest scaled time at the target city |
| `thousandths` | answer rounded to three decimals |

Integer scaling removes rounding error from comparisons between routes.

In the first sample dataset, using tickets with one, three, and two horses on roads of length ten, thirty, and twenty gives `10 + 10 + 10 = 30`. The scaled total is `75600`, which prints as `30.000`.

The final print adds half a thousandth before dividing by 2520, so ties round up.

## Code

**Input and scanning.** The reader loads all input once and parses nonnegative integers by hand.

```nim
const flushBlockBytes = 1 shl 17
const timeScale = 2520
const infiniteTime = high(int64) div 4

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
```

The terminator check reads all five header values.
Tickets and roads follow in fixed order.
The scanner ignores spaces and line breaks.

**Output helper.** One buffer collects every dataset result.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large outputs leave through one block write.
The remaining text flushes at the end.

**State relaxation.** Each city and ticket mask keeps one best scaled time.

```nim
while true:
  let ticketCount = nextInt(inputData, scanPos)
  let cityCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  let startCity = nextInt(inputData, scanPos)
  let targetCity = nextInt(inputData, scanPos)
  if ticketCount == 0 and cityCount == 0 and roadCount == 0 and startCity == 0 and targetCity == 0:
    break
  var ticketFactors = newSeq[int](ticketCount)
  for ticketIndex in 0 .. ticketCount - 1:
    let horseCount = nextInt(inputData, scanPos)
    ticketFactors[ticketIndex] = timeScale div horseCount
  var adjacency = newSeq[seq[int]](cityCount + 1)
  for roadIndex in 0 .. roadCount - 1:
    let firstCity = nextInt(inputData, scanPos)
    let secondCity = nextInt(inputData, scanPos)
    let roadLength = nextInt(inputData, scanPos)
    adjacency[firstCity].add secondCity
    adjacency[firstCity].add roadLength
    adjacency[secondCity].add firstCity
    adjacency[secondCity].add roadLength
  let maskCount = 1 shl ticketCount
  let rowWidth = cityCount + 1
  var bestTimes = newSeq[int64](maskCount * rowWidth)
  for stateIndex in 0 .. bestTimes.len - 1:
    bestTimes[stateIndex] = infiniteTime
  bestTimes[startCity] = 0
  for usedMask in 0 .. maskCount - 1:
    for currentCity in 1 .. cityCount:
      let baseIndex = usedMask * rowWidth + currentCity
      let baseTime = bestTimes[baseIndex]
      if baseTime == infiniteTime:
        continue
      for ticketIndex in 0 .. ticketCount - 1:
        if (usedMask and (1 shl ticketIndex)) != 0:
          continue
        let nextMask = usedMask or (1 shl ticketIndex)
        let rideFactor = ticketFactors[ticketIndex]
        let neighborList = adjacency[currentCity]
        var neighborPos = 0
        while neighborPos < neighborList.len:
          let neighborCity = neighborList[neighborPos]
          let roadLength = neighborList[neighborPos + 1]
          neighborPos += 2
          let candidateTime = baseTime + int64(roadLength * rideFactor)
          let candidateIndex = nextMask * rowWidth + neighborCity
          if candidateTime < bestTimes[candidateIndex]:
            bestTimes[candidateIndex] = candidateTime
  var bestAnswer = infiniteTime
  for usedMask in 0 .. maskCount - 1:
    let candidateTime = bestTimes[usedMask * rowWidth + targetCity]
    if candidateTime < bestAnswer:
      bestAnswer = candidateTime
  if bestAnswer == infiniteTime:
    appendOutput("Impossible\n")
  else:
    let thousandths = (bestAnswer * 1000 + int64(timeScale div 2)) div int64(timeScale)
    let wholePart = thousandths div 1000
    var fractionPart = $(thousandths mod 1000)
    while fractionPart.len < 3:
      fractionPart = "0" & fractionPart
    appendOutput($wholePart & "." & fractionPart & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each road is stored in both directions.
Only unused tickets create transitions.
An infinite final value produces the impossible message.

## Complexity

Masks and cities form the state space, and each state tries every unused ticket and its roads.

| phase | time | space |
|---|---|---|
| input read | one pass over dataset tokens | one input string |
| state relaxation | masks times cities times tickets times degree | scaled times table |
| answer scan | one pass over masks at the target | no extra space |
| output | one line per dataset | block buffer |

| measure | Big O |
|---|---|
| time per dataset | `O(2^n * m * n * d)` |
| space per dataset | `O(2^n * m)` |

A shortest-path search over unscaled floats would repeat more work and invite rounding drift.

The ticket mask carries the full coupon history in one integer.

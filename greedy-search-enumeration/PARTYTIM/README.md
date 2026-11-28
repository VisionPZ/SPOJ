# PARTYTIM — Party Time (SPOJ)

<https://www.spoj.com/problems/PARTYTIM/>

## Problem

Two elevators carry people from floors 0 through n-1 to the top floor n. Moving one elevator from floor i to floor j with x riders costs the XOR of the endpoint values and x. Report the minimum total cost when everyone arrives in the least possible time.

| item | bound |
|---|---|
| test cases | at most 10 |
| floors n | 1 to 30 |
| people in total | at most 1000, at least one per floor |
| elevator values | 0 to 1000 |
| judge limit | 1000 ms, 1536 MB |

Input starts with the test count. Each case gives n, the n+1 A values, the n+1 B values, and the n waiting counts. Output has one minimum-cost integer per line.

Sample input:

```
2
2
0 1 3
0 1 5
2 1
4
1 3 5 7 9
2 4 6 8 10
1 2 3 4
```

Sample output:

```
1
16
```

## Idea

Think of each elevator as a moving conveyor that may stop for good, like a bus that leaves the route. At every floor all available people can transfer freely between the elevators that are still running. A stopped elevator serves no later floor. Keep three costs, one for each set of running elevators, and add the cheapest XOR leg at every floor.

A naive search tracks the exact rider count of each elevator after every transfer. Aggregating people at a floor removes that whole dimension, leaving three numbers per floor.

## Why It Works

1. Minimum time requires every rider to move upward one floor per time unit.
2. An elevator that skips a leg cannot serve any later floor, so it may as well stop permanently.
3. An elevator that keeps running is present at every later floor, so people can board or leave it there at no cost.
4. At floor k, the total available riders equal the prefix sum of waiting counts through k.
5. Riders split between the running elevators, and each running elevator pays its own XOR leg even with zero riders.
6. The three costs, for A alone, B alone, and both, capture every possible set of running elevators.

| term | meaning |
|---|---|
| `totalPeople` | riders available at the current floor |
| `xorStepA` | `elevatorAValues[floorIndex] xor elevatorAValues[floorIndex + 1]` |
| `costActiveBoth` | cheapest cost with both elevators running |
| `bestShared` | cheapest split of riders over one leg |

The table names the values used in each floor transition.

A trace from the generator for the first sample case uses explicit rider states. At floor 0, two people split one and one.

```
floor 0: A cost 0 xor 1 xor 1 = 0, B cost 0 xor 1 xor 1 = 0
floor 1: three people, one newly waiting
A carries all three: 1 xor 3 xor 3 = 1, B stops
total 0 + 1 = 1
```

The generated answer 1 matches the sample.

## Code

**Input and scanning.** The hand reader loads all four lines of each case.

```nim
const flushBlockBytes = 1 shl 17
const infiniteCost = int64(1000000000000000000)

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

The scanner skips all separators.
Values fit in a signed 32-bit integer.
One buffer holds every case.

**Output buffer.** Buffered writes keep large test sets fast.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after 128 KiB.
Each answer is appended as one line.
A single flush closes the output.

**Floor sweep.** Three costs track which elevators still run.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let floorCount = nextInt(inputData, scanPos)
  var elevatorAValues = newSeq[int64](floorCount + 1)
  var elevatorBValues = newSeq[int64](floorCount + 1)
  for floorIndex in 0 .. floorCount:
    elevatorAValues[floorIndex] = int64(nextInt(inputData, scanPos))
  for floorIndex in 0 .. floorCount:
    elevatorBValues[floorIndex] = int64(nextInt(inputData, scanPos))
  var waitingPeople = newSeq[int](floorCount)
  for floorIndex in 0 .. floorCount - 1:
    waitingPeople[floorIndex] = nextInt(inputData, scanPos)
  var costActiveA = infiniteCost
  var costActiveB = infiniteCost
  var costActiveBoth: int64 = 0
  var totalPeople = 0
```

Both elevator arrays have n+1 entries.
The waiting array has n entries.
Both elevators start active at floor 0.

**Leg costs.** Each floor adds one leg for every running elevator.

```nim
  for floorIndex in 0 .. floorCount - 1:
    totalPeople = totalPeople + waitingPeople[floorIndex]
    let xorStepA = elevatorAValues[floorIndex] xor elevatorAValues[floorIndex + 1]
    let xorStepB = elevatorBValues[floorIndex] xor elevatorBValues[floorIndex + 1]
    var nextA = infiniteCost
    var nextB = infiniteCost
    var nextBoth = infiniteCost
    if costActiveA < infiniteCost:
      nextA = costActiveA + (xorStepA xor int64(totalPeople))
    if costActiveB < infiniteCost:
      nextB = costActiveB + (xorStepB xor int64(totalPeople))
    if costActiveBoth < infiniteCost:
      let aloneA = costActiveBoth + (xorStepA xor int64(totalPeople))
      let aloneB = costActiveBoth + (xorStepB xor int64(totalPeople))
      if aloneA < nextA:
        nextA = aloneA
      if aloneB < nextB:
        nextB = aloneB
      var bestShared = infiniteCost
      for passengersA in 0 .. totalPeople:
        let passengersB = totalPeople - passengersA
        let legCost = (xorStepA xor int64(passengersA)) +
                      (xorStepB xor int64(passengersB))
        if legCost < bestShared:
          bestShared = legCost
      nextBoth = costActiveBoth + bestShared
    costActiveA = nextA
    costActiveB = nextB
    costActiveBoth = nextBoth
```

A running elevator pays even with zero riders.
Stopping an elevator keeps the cost at zero from that floor on.
The shared case scans every split of the riders.

**Answer.** The cheapest final state is written.

```nim
  var bestCost = costActiveA
  if costActiveB < bestCost:
    bestCost = costActiveB
  if costActiveBoth < bestCost:
    bestCost = costActiveBoth
  appendOutput($bestCost)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The minimum covers all three running sets.
Costs stay in 64 bits.
One flush writes every answer.

## Complexity

The floor sweep dominates; the split scan runs at most 1001 times per floor.

| phase | time | space |
|---|---|---|
| input read | one pass over case tokens | one input string |
| floor sweep | 30 floors times 1001 splits | three cost values |
| output | one write per block | one output string |

The table shows that the split scan sets the per-case cost.

| measure | Big O |
|---|---|
| time per case | O(n * P), P total people |
| space per case | O(n) for the arrays |

Tracking every rider split at every floor without aggregating would multiply the state space by P, so the three aggregated costs are the practical choice.

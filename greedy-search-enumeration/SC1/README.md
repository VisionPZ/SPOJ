# SC1 — Starcraft I (SPOJ)

<https://www.spoj.com/problems/SC1/>

## Problem

Find the shortest time to collect required minerals and gas when probes can mine and the nexus can build more probes. A probe costs z minerals, takes three ST to finish, and cannot mine while under construction.

The first line holds the number of test cases. Each case has six integers: n, x, y, z, A, B. Here n is the starting probe count. Values x and y are mineral and gas rates per probe per ST. Value z is the build cost. Values A and B are the goals. Each answer line holds the minimum integer time in ST.

| item | bound |
|---|---|
| test cases | given by the first line |
| each input number | positive and below 21 |
| build time | 3 ST per probe |
| judge limit | 2000 ms, 1536 MB |

Only one probe can be built at a time, and all active probes mine in parallel.

Sample input:

```
1
1 2 3 4 5 6
```

Sample output:

```
5
```

## Idea

Try each possible number of new probes, like deciding how many extra workers to hire before a deadline. For a fixed count, start each build as early as minerals allow. Then count the probe-ST available by the finish time and check the goals. The best candidate across all build counts is the answer. Simulating every possible mining choice would explore far more schedules.

## Why It Works

1. A build starts only when saved minerals reach z.
2. While a build runs, the active probes keep mining minerals for the next build.
3. A build started at time t finishes at t + 3 and adds one active probe.
4. With k builds, total probe-ST by time T equals (n + k)T minus the completion times.
5. The mineral goal needs ceil((A + kz)/x) probe-ST and the gas goal needs ceil(B/y).
6. The smallest feasible T for that k is the larger of the last completion and that work bound.

| term | meaning |
|---|---|
| `savedMinerals` | minerals held beyond payments for started builds |
| `completionSum` | sum of all build completion times |
| `mineralWork` | probe-ST needed for builds plus the mineral goal |
| `gasWork` | probe-ST needed for the gas goal |

The two work terms share the same pool of active probe-ST.

The generator traces the sample case with explicit numbers:

| builds | last completion | probe-ST needed | earliest time |
|---|---|---|---|
| 0 | 0 | 3 + 2 = 5 | 5 |
| 1 | 5 | 5 + 2 + 5 = 12 | 6 |

The best time is 5, matching the sample output.

## Code

**Input and helpers.** The reader loads all tokens and defines ceiling division.

```nim
const flushBlockBytes = 1 shl 17
const constructionTime = 3
const maximumBuilds = 100

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

proc ceilDivide(value: int, divisor: int): int =
  return (value + divisor - 1) div divisor

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Ceiling division keeps all times integral.
Scanning ignores spacing and line breaks.
The buffer collects answer lines in blocks.

**Build schedule.** Each build count gets its earliest legal schedule.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let initialProbes = nextInt(inputData, scanPos)
  let mineralRate = nextInt(inputData, scanPos)
  let gasRate = nextInt(inputData, scanPos)
  let probeCost = nextInt(inputData, scanPos)
  let mineralGoal = nextInt(inputData, scanPos)
  let gasGoal = nextInt(inputData, scanPos)
  var bestTime = maximumBuilds * constructionTime + mineralGoal + gasGoal
  var buildCount = 0
  while buildCount <= maximumBuilds:
    var elapsed = 0
    var savedMinerals = 0
    var activeProbes = initialProbes
    var completionSum = 0
    var lastCompletion = 0
    var usable = true
    for buildIndex in 0 .. buildCount - 1:
      if savedMinerals < probeCost:
        let waitingTime = ceilDivide(probeCost - savedMinerals, activeProbes * mineralRate)
        elapsed += waitingTime
        savedMinerals += activeProbes * mineralRate * waitingTime
      savedMinerals -= probeCost
      savedMinerals += activeProbes * mineralRate * constructionTime
      elapsed += constructionTime
      activeProbes += 1
      completionSum += elapsed
      lastCompletion = elapsed
      if lastCompletion >= bestTime:
        usable = false
        break
```

Waiting stops as soon as the build cost is covered.
Each finished probe raises the mining rate for later work.
A build count is dropped once its last completion cannot improve the best time.

**Time bound.** The work bound turns probe-ST into a horizon.

```nim
    if usable:
      let mineralWork = ceilDivide(mineralGoal + buildCount * probeCost, mineralRate)
      let gasWork = ceilDivide(gasGoal, gasRate)
      let finishingTime = ceilDivide(mineralWork + gasWork + completionSum, initialProbes + buildCount)
      let candidateTime = lastCompletion
      if finishingTime > candidateTime:
        bestTime = min(bestTime, finishingTime)
      else:
        bestTime = min(bestTime, candidateTime)
    buildCount += 1
  appendOutput($(bestTime))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The horizon must also reach the last completion.
The smallest horizon over all build counts is printed.
One buffered line is written per test case.

## Complexity

Each case tries at most one hundred build counts.

| phase | time | space |
|---|---|---|
| input read | one pass over six values per case | one input string |
| build counts | at most 100 schedules of length 100 | a few integers |
| output | one buffered line per case | block buffer |

The schedule length is bounded by the best time already found.

| measure | Big O |
|---|---|
| time | O(K^2) per case, K at most 100 |
| space | O(1) beyond input and buffer |

Enumerating every mining decision per ST would be much slower. Try each build count once and compute its earliest finish directly.

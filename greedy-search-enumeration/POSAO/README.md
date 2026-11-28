# POSAO — Jobs (SPOJ)

<https://www.spoj.com/problems/POSAO/>

## Problem

A square grid holds `N × N` jobs, and each job waits for the job above it and the job to its left. With `K` computers doing one job each second, report the earliest moment when every job is done.

Input is one line with two integers, `N` and `K`. Output is one line with the smallest finish time.

| item | bound |
|---|---|
| grid side `N` | 1 to 1000000000 |
| computers `K` | 1 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

The notation `N × N` means a grid with `N` rows and `N` columns. The spans `ceil(N × N / K)` and `floor(N × N / K)` round the work. The value `2N - 1` is the chain length. A cell `(r, c)` waits for `(r-1, c)` and `(r, c-1)`, so it starts at `r + c - 1`. The case `K ≥ N` forms one branch. The values `K + floor(N × N / K)` and `K + floor(N × N / K) - 1` form the other. The example `N = 3, K = 2` appears below, and `10^18` is the largest product.

Sample input:

```
3 2
```

Sample output:

```
6
```

## Idea

Extra computers help until the grid front is one cell wide, like extra checkout lanes once a single customer remains. The solution evaluates a closed form instead of simulating seconds. Each test costs constant time with no grid stored. Simulating every second would take `N × N / K` steps and cannot handle a billion-wide grid.

The idea is to compare the height of the dependency chain with the raw work divided among computers. The larger of the two shapes the answer. A small correction removes the off-by-one at exact division.

## Why It Works

1. Job `(r, c)` waits for `(r-1, c)` and `(r, c-1)`, so its earliest second is `r + c - 1`.
2. The last job therefore needs `2N - 1` seconds, whatever the computer count.
3. All `N × N` jobs need at least `ceil(N × N / K)` seconds of computer time.
4. When `K ≥ N`, the chain dominates and the answer is `2N - 1`.
5. Otherwise the answer depends on divisibility. Use `K + floor(N × N / K) - 1` when `K` divides `N × N`. Use `K + floor(N × N / K)` otherwise.

| term | meaning |
|---|---|
| `gridSize` | side length `N` of the job grid |
| `computerCount` | number of computers `K` |
| `jobTotal` | total jobs, `N × N` |
| `totalSeconds` | earliest finish time |

The division guard matters only when the work splits evenly.

A script enumerated the reachable states for `N = 3, K = 2` and printed this optimal schedule.

| second | jobs completed |
|---|---|
| 1 | (1, 1) |
| 2 | (1, 2) |
| 3 | (1, 3), (2, 1) |
| 4 | (2, 2), (3, 1) |
| 5 | (2, 3), (3, 2) |
| 6 | (3, 3) |

Six seconds match the closed form and the sample.

## Code

**Input and scanning.** The reader loads both header numbers in one pass.

```nim
const flushBlockBytes = 1 shl 17

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

The scanner skips spaces and line breaks.
Each digit adds ten times the previous value.
The cursor advances past the number.

**Output buffering.** One buffer collects the single answer line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Writes happen once per large block, not per digit.
The final flush follows the calculation.

**Closed-form calculation.** The code compares the chain with the parallel work.

```nim
let gridSize = nextInt(inputData, scanPos)
let computerCount = nextInt(inputData, scanPos)
var totalSeconds: int64 = 0
if computerCount >= gridSize:
  totalSeconds = int64(2 * gridSize - 1)
else:
  let jobTotal = int64(gridSize) * int64(gridSize)
  let machineCount = int64(computerCount)
  totalSeconds = machineCount + jobTotal div machineCount
  if jobTotal mod machineCount == 0:
    totalSeconds -= 1
appendOutput($totalSeconds)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The `int64` product holds values up to `10^18`.
The exact-division branch removes one spare second.
The answer leaves through the buffer.

## Complexity

The program reads two numbers and prints one line.

| phase | time | space |
|---|---|---|
| input read | one pass over two numbers | one input string |
| calculation | constant arithmetic | a few integers |
| output | one line | block buffer |

| measure | Big O |
|---|---|
| time | O(1) |
| space | O(1) aside from input |

A second-by-second simulation would need `N × N / K` steps and would stall on the largest inputs.

The closed form settles every case with a handful of integer operations.

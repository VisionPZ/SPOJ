# BALIFE — Load Balancing (SPOJ)

<https://www.spoj.com/problems/BALIFE/>

## Problem

Find the fewest rounds that make every processor hold the same number of jobs. In one round each processor may send at most one job left and one job right.

Input: several blocks, each starting with processor count N. The next N integers give the starting job counts. A line with -1 ends the file. Output: one line per block with the minimum rounds, or -1 when equal loads are impossible.

| item | bound |
|---|---|
| processors N | 1 to 9000 |
| job counts | nonnegative integers |
| terminator | -1 |
| judge limit | 1000 ms, 1536 MB |

Equal loads exist only when the total divides evenly by N.

The sample holds four blocks before the terminator.

| sample job counts | sample answer |
|---|---|
| 0 99 3 | 34 |
| 49 50 | -1 |
| 16 17 15 0 20 1 1 2 | 23 |
| 0 0 100 0 0 0 0 0 0 0 | 70 |

The second block fails because 99 does not divide by two.

## Idea

Track the running surplus across each gap, like measuring how many cars must cross each bridge on a one-lane road. The answer is the largest absolute surplus over all gaps. The algorithm is a prefix-sum sweep with one subtraction per processor. A simulation that moves jobs round by round costs far more than one pass. Compute the bound directly and emit one answer per block.

## Why It Works

1. Let the target be the total divided by N, and let a surplus be a load minus that target.
2. The running sum of surpluses through processor i equals the net jobs crossing the gap after i.
3. A positive running sum sends jobs right; a negative one sends jobs left.
4. One job per round crosses a gap in one direction, so the largest absolute running sum is a lower bound.
5. A processor may send one job to each neighbor in the same round, and the two needed directions always fit inside that bound.
6. Every block with an indivisible total has no solution and yields -1.

| term | meaning |
|---|---|
| `targetJobs` | total jobs divided by processor count |
| `runningFlow` | net jobs that must cross the current gap |
| `largestFlow` | maximum absolute running flow over all gaps |
| `totalJobs` | sum of all starting job counts |

The largest flow is the whole answer because each gap moves at most one job per round.

A scripted trace for the first sample block gives visible numbers.

| processor | surplus | running flow |
|---|---|---|
| 1 | -34 | -34 |
| 2 | 65 | 31 |
| 3 | -31 | 0 |

The largest absolute flow is 34, which matches the sample answer.

Integer division decides divisibility before the sweep starts, so no rounding enters the result.

## Code

**Input and scanning.** The reader handles the negative terminator and stores each block.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and not ((data[pos] >= '0' and data[pos] <= '9') or data[pos] == '-'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner accepts a leading minus only for the terminator.
Blank lines between blocks are skipped by the digit scan.
The buffer flushes after a large block of answer lines.

**Prefix sweep.** One pass checks divisibility and finds the largest net flow.

```nim
while true:
  let processorCount = nextInt(inputData, scanPos)
  if processorCount == -1:
    break
  var totalJobs: int64 = 0
  var jobCounts = newSeq[int64](processorCount)
  for processorIndex in 0 .. processorCount - 1:
    let jobCount = int64(nextInt(inputData, scanPos))
    jobCounts[processorIndex] = jobCount
    totalJobs += jobCount
  if (totalJobs mod int64(processorCount)) != 0:
    appendOutput("-1")
    outputBuffer.add '\n'
    continue
  let targetJobs = totalJobs div int64(processorCount)
  var runningFlow: int64 = 0
  var largestFlow: int64 = 0
  for processorIndex in 0 .. processorCount - 2:
    runningFlow += jobCounts[processorIndex] - targetJobs
    let flowSize = if runningFlow < 0: -runningFlow else: runningFlow
    if flowSize > largestFlow:
      largestFlow = flowSize
  appendOutput($largestFlow)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The sweep stops before the last processor because the final flow is zero.
Sums use 64-bit integers to hold large job totals.
The terminator ends the loop before any further parsing.

## Complexity

Each block needs one total pass and one prefix pass.

| phase | time | space |
|---|---|---|
| input read | one pass over all blocks | one input string |
| prefix sweep | one subtraction per processor | one job array |
| output | one block per answer | output buffer |

The two linear passes dominate the runtime.

| measure | Big O |
|---|---|
| time | O(N) per block |
| space | O(N) |

Naive round-by-round simulation repeats work for every round, while the sweep computes the answer directly.

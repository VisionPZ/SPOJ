# DERP — Derp (SPOJ)

<https://www.spoj.com/problems/DERP/>

## Problem

Each particle sits on a layer at a grid position. An electron moves one layer at a time, so travel cost adds the layer gap to both coordinate gaps. The task reports the largest cost between any two particles.

Input holds several samples. Each sample starts with N, then N lines of layer, x, and y. A line with N = 0 ends the input.

Output gives one maximum distance per sample, on its own line.

The bounds from the statement:

| item | bound |
|---|---|
| particles per sample | 2 to 100000 |
| layer, x, y values | 1 to 1000000000 |
| samples | until N = 0 |
| judge limit | 1000 ms, 1536 MB |

The large coordinate range makes a 64-bit sum necessary.

Sample input:

```
5
1 1 2
3 4 1
2 5 7
4 1 1
3 3 3
0
```

The sample holds five particles and a terminating zero.

Sample output:

```
12
```

Particles 3 and 4 are 12 grid steps apart.

## Idea

Stretch the cloud along eight diagonals, like measuring a tilted box from opposite corners. The farthest pair shows up as the widest gap on one diagonal.

The method is the eight-sign Manhattan transform. Each particle contributes one value per sign mask, and each mask needs only a running minimum and maximum. Cost is eight updates per particle, so the scan is linear.

Comparing every pair costs quadratic time and cannot handle 100000 particles. Eight masks replace all pairs.

## Why It Works

1. Travel cost is the layer gap plus the x gap plus the y gap.
2. Pick signs for the three coordinates, then form their signed sum for each particle.
3. For that sign choice, the widest spread equals the largest cost over all pairs with matching difference signs.
4. Three coordinates give eight sign choices, and one choice fits the farthest pair.
5. The largest spread across the eight choices is the required distance.

The main terms and formulas:

| term | meaning |
|---|---|
| `signLayer` | sign applied to the layer for one mask |
| `signCoordX` | sign applied to the x coordinate for one mask |
| `signCoordY` | sign applied to the y coordinate for one mask |
| `extremeMin` | smallest signed sum seen for one mask |
| `extremeMax` | largest signed sum seen for one mask |
| `farthestDistance` | largest spread across all masks |

Every mask direction fits one pair of particles.

A script trace over the sample particles gives these spreads:

```
mask +1+1+1: min   4 max  14 spread  10
mask -1+1+1: min  -2 max  10 spread  12
mask +1-1+1: min   0 max   4 spread   4
mask -1-1+1: min  -6 max   0 spread   6
mask +1+1-1: min   0 max   6 spread   6
mask -1+1-1: min  -4 max   0 spread   4
mask +1-1-1: min -10 max   2 spread  12
mask -1-1-1: min -14 max  -4 spread  10
```

The widest spread is 12, which matches the sample answer.

Signed sums stay far below the 64-bit limit, so no rounding guard is needed.

## Code

**Input and scanner.** One read loads stdin, and the hand scanner skips separators.

```nim
const flushBlockBytes = 1 shl 17
const signCount = 8

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

The loop runs once per input line.
The scanner advances one index past each token.
Parsing ignores line breaks and extra spaces.

**Output buffer.** Text accumulates in one string and flushes in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The block size is 131072 bytes.
The buffer clears after each flush.
One final write emits any remaining text.

**Eight-mask scan.** Each particle updates eight signed extremes.

```nim
var signLayer = newSeq[int](signCount)
var signCoordX = newSeq[int](signCount)
var signCoordY = newSeq[int](signCount)
for mask in 0 .. signCount - 1:
  signLayer[mask] = if (mask and 1) == 0: 1 else: -1
  signCoordX[mask] = if (mask and 2) == 0: 1 else: -1
  signCoordY[mask] = if (mask and 4) == 0: 1 else: -1

var extremeMin = newSeq[int64](signCount)
var extremeMax = newSeq[int64](signCount)
while true:
  let particleCount = nextInt(inputData, scanPos)
  if particleCount == 0:
    break
  for mask in 0 .. signCount - 1:
    extremeMin[mask] = high(int64)
    extremeMax[mask] = low(int64)
  for particleIndex in 0 .. particleCount - 1:
    let layerValue = nextInt(inputData, scanPos)
    let coordXValue = nextInt(inputData, scanPos)
    let coordYValue = nextInt(inputData, scanPos)
    for mask in 0 .. signCount - 1:
      let signedValue = int64(signLayer[mask]) * int64(layerValue) +
                        int64(signCoordX[mask]) * int64(coordXValue) +
                        int64(signCoordY[mask]) * int64(coordYValue)
      if signedValue < extremeMin[mask]:
        extremeMin[mask] = signedValue
      if signedValue > extremeMax[mask]:
        extremeMax[mask] = signedValue
  var farthestDistance = int64(0)
  for mask in 0 .. signCount - 1:
    let spread = extremeMax[mask] - extremeMin[mask]
    if spread > farthestDistance:
      farthestDistance = spread
  appendOutput($farthestDistance)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The zero count ends the last sample.
Each mask keeps two running extremes.
The answer is one line per sample.

## Complexity

Work divides into reading, scanning, and writing.

| phase | time | space |
|---|---|---|
| input read | one pass over the input string | one input string |
| eight-mask scan | eight updates per particle | two arrays of eight values |
| output | one line per sample | block buffer |

The scan dominates on large samples.

The overall asymptotic bounds:

| measure | Big O |
|---|---|
| time | O(8N) per sample |
| space | O(1) beyond the input string |

Pairwise comparison would cost O(N^2) per sample. The eight-mask scan replaces it with one linear pass.

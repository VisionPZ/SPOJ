# CISTFILL — Fill the Cisterns (SPOJ)

<https://www.spoj.com/problems/CISTFILL/>

## Problem

Cisterns sit at given base levels with given dimensions, and a fixed water volume fills the connected network. Find the water level reached, or report overflow.

Input: one integer for the data-set count, then one data set per block. Each block starts with a cistern count, then one line of base, height, width, and depth per cistern, then the water volume.

Output: the level the water reaches, printed with two digits after the decimal point. Print `OVERFLOW` when the volume exceeds the total capacity.

The statement and judge give these bounds:

| Item | Bound |
| --- | --- |
| Data sets | 1 to 30 |
| Cisterns per set | 1 to 50000 |
| Base level | 0 to 1000000 |
| Height times width times depth | 1 to 40000 |
| Volume | 1 to 2000000000 |
| Time limit | 13000 ms |
| Memory limit | 1536 MB |

The number of output lines equals the number of data sets.

The sample input and output:

```
3
2
0 1 1 1
2 1 1 1
1
4
11 7 5 1
15 6 2 2
5 8 5 1
19 4 8 1
132
4
11 7 5 1
15 6 2 2
5 8 5 1
19 4 8 1
78
```

```
1.00
OVERFLOW
17.00
```

## Idea

Walk the water level upward, like reading a row of gauges from the bottom to the top. Each cistern opens at its base and closes at its top.

The program records an area gain at each base and an area loss at each top. A sweep adds those changes level by level and keeps the active cross-section area. The filled volume grows by that area at every step.

Each cistern creates two events, and each level costs constant work. Testing every candidate level against every cistern would cost O(n) work per trial.

One sweep replaces all those repeated trials.

## Why It Works

The volume below a level follows from one sum over the cisterns.

1. A cistern at base b with height h and area a holds `a × min(L - b, h)` below level L.
2. Summed over all cisterns, that volume grows with L. It crosses the poured volume once.
3. Adding a at the base and subtracting a at the top leaves exactly the area active at the next level.
4. When the remaining volume fits one level step, the answer is that level plus the remaining volume divided by the active area.

The arrays and counters carry the following facts:

| Term | Meaning |
| --- | --- |
| `startArea[level]` | cross-section area starting at that level |
| `endArea[level]` | cross-section area ending at that level |
| `activeArea` | total area of cisterns holding water now |
| `filledVolume` | water placed below the current level |
| `highestLevel` | highest top level in the data set |

The numerator stays integral until the final division, which keeps rounding stable.

A script traces the third sample data set, which pours volume 78:

```
level  event  active area  volume filled
5      +5     5            5
11     +5     10           30
13     -5     5            50
15     +4     9            60
16     0      9            69
```

At level 16 the remaining volume is 9 and the active area is 9. The answer is `16 + 9/9 = 17.00`, which matches the sample.

## Code

**Constants and scanner.** The two arrays span every legal level, and the scanner reads digits without building tokens.

```nim
import strutils

const levelLimit = 1_050_000
const firstDigitValue = 48
const flushBlockBytes = 1 shl 16

var startArea: array[0..levelLimit, int64]
var endArea: array[0..levelLimit, int64]

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ': inc i
  result = 0
  while i < inputData.len and inputData[i] >= '0':
    result = result * 10 + (int(inputData[i]) - firstDigitValue)
    inc i
```

The arrays are global, so no large allocation runs inside the data-set loop. The digit loop stops at the first non-digit and allocates no string. The value 48 converts a digit character to its number.

**Case setup.** The program clears only levels touched by the previous data set.

```nim
proc solve() =
  let inputData = readStreamBytes()
  var i = 0
  let dataSetCount = nextInt(inputData, i)
  var outputBuffer = ""
  var clearedThrough = 0
  for j in 0 ..< dataSetCount:
    for k in 0 .. clearedThrough:
      startArea[k] = 0
      endArea[k] = 0
    let cisternCount = nextInt(inputData, i)
    var highestLevel = 0
    for k in 0 ..< cisternCount:
      let baseLevel = nextInt(inputData, i)
      let cisternHeight = nextInt(inputData, i)
      let cisternWidth = nextInt(inputData, i)
      let cisternDepth = nextInt(inputData, i)
      let crossArea = int64(cisternWidth * cisternDepth)
      let topLevel = baseLevel + cisternHeight
      startArea[baseLevel] += crossArea
      endArea[topLevel] += crossArea
      if topLevel > highestLevel: highestLevel = topLevel
    clearedThrough = highestLevel
    let waterVolume = int64(nextInt(inputData, i))
```

The clear loop ends at the previous highest level, so data sets stay independent. Each cistern writes two events in constant time. One pass through the buffer reads every integer.

**Level sweep.** One integer step adds the area change and tests the remaining volume.

```nim
    var activeArea: int64 = 0
    var filledVolume: int64 = 0
    var reachedLevel = 0.0
    var answerFound = false
    var k = 0
    while k <= highestLevel:
      activeArea += startArea[k] - endArea[k]
      if activeArea > 0:
        let neededVolume = waterVolume - filledVolume
        if neededVolume <= activeArea:
          reachedLevel = float(k * activeArea + neededVolume) / float(activeArea)
          answerFound = true
          break
        filledVolume += activeArea
      inc k
```

The loop visits at most `highestLevel + 1` levels. Subtracting `endArea` at the same level stops a finished cistern from filling higher levels. The division happens once, after the multiplication stays integral.

**Output.** Formatting uses two decimal places, and an oversized volume prints a word.

```nim
    if answerFound:
      outputBuffer.add(formatFloat(reachedLevel, ffDecimal, 2))
    else:
      outputBuffer.add("OVERFLOW")
    outputBuffer.add('\n')
    if outputBuffer.len >= flushBlockBytes:
      stdout.write(outputBuffer)
      outputBuffer.setLen(0)
  stdout.write(outputBuffer)

solve()
```

The flush triggers when the buffer passes 64 KiB. `formatFloat` prints exactly two fractional digits. The final write emits the remaining lines.

## Complexity

Reading costs time linear in the integer count, and the sweep visits one level per step.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Event build | O(n) per data set | O(level limit) |
| Level sweep | O(maxLevel) per data set | O(1) extra |
| Output | one write per 64 KiB block | 64 KiB |
| Total per set | O(maxLevel + n) | O(level limit) |

At the largest base level the arrays hold about 1.05 million slots each.

The asymptotic bounds are as follows:

| Measure | Big O |
| --- | --- |
| Time | O(k × (maxLevel + n)) for k data sets |
| Space | O(level limit) |

Testing each level against every cistern would cost O(n × maxLevel) per data set.

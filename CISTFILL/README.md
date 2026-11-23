## Problem

Read several data sets. Each data set lists cisterns and a water volume. A cistern (a rectangular tank) has a base level, a height, a width, and a depth. Print the level the water reaches, rounded to two fractional digits. Print OVERFLOW when the volume exceeds the total capacity of the cisterns.

The table lists every input bound and the judge limits.

| quantity | bound |
|----------|-------|
| data sets | 1 to 30 |
| cisterns per data set | 1 to 50000 |
| base level | 0 to 1000000 |
| height times width times depth | 1 to 40000 |
| volume | 1 to 2000000000 |
| time limit | 13000 ms |
| memory limit | 1536 MB |

The number of output lines equals the number of data sets.

## Idea

A sweep (a walk through increasing levels) solves each data set. At each level, the program starts new cisterns and removes finished ones. It keeps the active cross-section area (width times depth) of the cisterns that hold water. One level step adds that area to the filled volume. The walk stops when the filled volume reaches the injected volume. Each level costs constant work, and each cistern creates two events.

## Why It Works

Water fills every cistern below the surface. A cistern at base b with height h and area a holds a times min of L minus b and h. Adding this term over all cisterns gives the volume below L. That sum grows with L and reaches the injected volume once.

The program adds area a at the base level and subtracts area a at the top level. After both changes, the active area covers the next level step. The filled volume grows by that area. When the remaining volume fits the step, the answer is the current level plus the remaining volume divided by the active area.

The script-generated example uses the third sample data set with volume 78.

| sweep level | area added | area removed | active area | volume before |
|-------------|------------|--------------|-------------|---------------|
| 5 | +5 | -0 | 0 | 0 |
| 11 | +5 | -0 | 5 | 0 |
| 13 | +0 | -5 | 10 | 30 |
| 15 | +4 | -0 | 5 | 50 |
| 18 | +0 | -5 | 9 | 60 |

The crossing happens at level 15 with active area 9. The remaining volume is 18, so the answer is 17.00.

## Code

The two arrays store one entry per level. The scanner reads digits without building token strings.

```nim
import strutils

const levelLimit = 1_050_000
const firstDigitValue = 48
const flushBlockBytes = 1 shl 16

var startArea: array[0..levelLimit, int64]
var endArea: array[0..levelLimit, int64]

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ': inc scanPos
  result = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0':
    result = result * 10 + (int(inputData[scanPos]) - firstDigitValue)
    inc scanPos
```

The digit loop ends at the first non-digit, so no token is allocated. Character codes use the constant 48, which works on the judge compiler. Global arrays avoid a large allocation inside the loop over data sets.

The reading block clears only levels that the previous data set touched.

```nim
proc solve() =
  let inputData = stdin.readAll()
  var scanPos = 0
  let dataSetCount = nextInt(inputData, scanPos)
  var outputBuffer = ""
  var clearedThrough = 0
  for dataSetIndex in 0 ..< dataSetCount:
    for levelIndex in 0 .. clearedThrough:
      startArea[levelIndex] = 0
      endArea[levelIndex] = 0
    let cisternCount = nextInt(inputData, scanPos)
    var highestLevel = 0
    for cisternIndex in 0 ..< cisternCount:
      let baseLevel = nextInt(inputData, scanPos)
      let cisternHeight = nextInt(inputData, scanPos)
      let cisternWidth = nextInt(inputData, scanPos)
      let cisternDepth = nextInt(inputData, scanPos)
      let crossArea = int64(cisternWidth * cisternDepth)
      let topLevel = baseLevel + cisternHeight
      startArea[baseLevel] += crossArea
      endArea[topLevel] += crossArea
      if topLevel > highestLevel: highestLevel = topLevel
    clearedThrough = highestLevel
    let waterVolume = int64(nextInt(inputData, scanPos))
```

The clear loop runs from zero through clearedThrough, the highest level of the previous data set. Clearing touched levels keeps data sets independent. One pass through the buffer reads every integer.

The sweep block walks one integer level at a time.

```nim
    var activeArea: int64 = 0
    var filledVolume: int64 = 0
    var reachedLevel = 0.0
    var answerFound = false
    var levelIndex = 0
    while levelIndex <= highestLevel:
      activeArea += startArea[levelIndex] - endArea[levelIndex]
      if activeArea > 0:
        let neededVolume = waterVolume - filledVolume
        if neededVolume <= activeArea:
          reachedLevel = float(levelIndex * activeArea + neededVolume) / float(activeArea)
          answerFound = true
          break
        filledVolume += activeArea
      inc levelIndex
```

The while loop runs at most highestLevel plus one times. Subtracting endArea at the same level stops a finished cistern from filling higher levels. The numerator stays integral until the final division, which keeps rounding stable.

The output block buffers lines and writes them in blocks.

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

The flush triggers when the buffer passes flushBlockBytes bytes. formatFloat prints two fractional digits, and the literal OVERFLOW replaces a number when capacity is too small. The final write flushes the remaining lines.

## Complexity

Reading the integers costs time linear in their count. The sweep visits highestLevel plus one levels per data set, and each cistern changes two array entries. Output is one line per data set.

Total time is O(k times (maxLevel plus n)), with k at most 30 and maxLevel at most 1040000. Space is O(levelLimit) for the two area arrays. A naive search would test each candidate level against every cistern, costing O(n) work per trial.

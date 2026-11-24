## Problem

Read block types case by case. Each type gives three side lengths, and zero ends the input. Rotate each block as needed and copy it without limit. A block rests on another only when both base sides are strictly shorter. Print the tallest possible tower per case.

The stated bounds and judge limits follow.

| Quantity | Bound |
| --- | --- |
| Block types per case | 1 to 30 |
| Largest side | 2,500 |
| Test cases | Unbounded; zero ends input |
| Time limit | 3,000 ms |
| Memory limit | 1,536 MB |

At most 90 candidate blocks describe any single case.

## Idea

An orientation is one choice of which side stands upright, and each block type gives three of them. Rotating each base so the long side comes first lets us sort all orientations by base from large to small. One scan adds each height to the best earlier tower with both sides smaller, costing O(n) per orientation instead of enumerating stacks.

## Why It Works

Both base sides shrink at every step down a tower. The bases therefore form a strict order, no base repeats, and one scan visits every possible lower block before the current one. The stored tower total already includes everything under that block.

Each formula below records one step of the scan.

- `baseLarge[orientationCount] = max(givenWidth, givenDepth)` keeps the wider base side first.
- `baseSmall[orientationCount] = min(givenWidth, givenDepth)` keeps the narrower base side second.
- `baseLarge[j] > baseLarge[i] and baseSmall[j] > baseSmall[i]` tests both sides strictly.
- `towerHeight[i] = blockHeight[i] + bestBelow` extends a whole lower tower by one block.

The trace below uses the two block types 1 2 3 and 2 3 4.

| Base | Height | Best lower tower | Tower total |
| --- | --- | --- | --- |
| 4 x 3 | 2 | 0 | 2 |
| 4 x 2 | 3 | 0 | 3 |
| 3 x 2 | 1 | 2 | 3 |
| 3 x 2 | 4 | 2 | 6 |
| 3 x 1 | 2 | 3 | 5 |
| 2 x 1 | 3 | 6 | 9 |

The last row gives the answer 9.

## Code

```
const
  spaceCode = 32
  firstDigitCode = 48
  flushBlockBytes = 1 shl 18
  maxBlockTypes = 30
  orientationsPerType = 3
  maxOrientations = maxBlockTypes * orientationsPerType

var
  inputData = ""
  i = 0
  outputBuffer = ""
  baseLarge: array[maxOrientations, int]
  baseSmall: array[maxOrientations, int]
  blockHeight: array[maxOrientations, int]
  towerHeight: array[maxOrientations, int]
```

The fixed arrays hold 90 slots, three times the type cap. No allocation happens inside the case loop, and each slot keeps one base pair and one height.

```
proc loadInput() =
  var lineContents = ""
  while readLine(stdin, lineContents):
    inputData.add lineContents
    inputData.add '\n'

proc skipWhitespace() =
  while i < inputData.len and ord(inputData[i]) <= spaceCode:
    inc i

proc readInteger(): int =
  skipWhitespace()
  result = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    result = result * 10 + (ord(inputData[i]) - firstDigitCode)
    inc i
```

The read loop runs once per input line and stores all bytes in one buffer. The scanner walks that buffer by index and absorbs carriage returns as whitespace. This costs one pass over the input.

```
proc buildOrientations(blockTypeCount: int) =
  var orientationCount = 0
  for i in 0 ..< blockTypeCount:
    let givenHeight = readInteger()
    let givenWidth = readInteger()
    let givenDepth = readInteger()
    baseLarge[orientationCount] = max(givenWidth, givenDepth)
    baseSmall[orientationCount] = min(givenWidth, givenDepth)
    blockHeight[orientationCount] = givenHeight
    inc orientationCount
    baseLarge[orientationCount] = max(givenHeight, givenDepth)
    baseSmall[orientationCount] = min(givenHeight, givenDepth)
    blockHeight[orientationCount] = givenWidth
    inc orientationCount
    baseLarge[orientationCount] = max(givenHeight, givenWidth)
    baseSmall[orientationCount] = min(givenHeight, givenWidth)
    blockHeight[orientationCount] = givenDepth
    inc orientationCount
```

The loop runs exactly blockTypeCount times and writes three orientations each time. Each base stores its long side first. This costs O(n) per case.

```
proc sortOrientations(orientationCount: int) =
  for i in 1 ..< orientationCount:
    var j = i
    while j > 0:
      let k = j - 1
      let outOfOrder = baseLarge[k] < baseLarge[j] or
                       (baseLarge[k] == baseLarge[j] and baseSmall[k] < baseSmall[j])
      if not outOfOrder: break
      let largeValue = baseLarge[j]
      let smallValue = baseSmall[j]
      let heightValue = blockHeight[j]
      baseLarge[j] = baseLarge[k]
      baseSmall[j] = baseSmall[k]
      blockHeight[j] = blockHeight[k]
      baseLarge[k] = largeValue
      baseSmall[k] = smallValue
      blockHeight[k] = heightValue
      dec j
```

The outer loop runs to orientationCount minus one, and the inner loop walks back to the start. Insertion sort is cheap for at most 90 items. This puts every possible lower block earlier in the array.

```
proc tallestTower(orientationCount: int): int =
  var bestTower = 0
  for i in 0 ..< orientationCount:
    var bestBelow = 0
    for j in 0 ..< i:
      if baseLarge[j] > baseLarge[i] and baseSmall[j] > baseSmall[i]:
        if towerHeight[j] > bestBelow:
          bestBelow = towerHeight[j]
    towerHeight[i] = blockHeight[i] + bestBelow
    if towerHeight[i] > bestTower:
      bestTower = towerHeight[i]
  result = bestTower
```

The outer loop runs orientationCount times and the inner loop scans all earlier slots. The compatibility test rejects equal sides, so a block never rests on itself. This costs O(n²) per case.

```
proc flushOutput(forceAll: bool) =
  if forceAll or outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes at 256 KiB or at the end of input. No write happens per tower. This keeps write calls rare.

```
loadInput()
while true:
  skipWhitespace()
  if i >= inputData.len: break
  let blockTypeCount = readInteger()
  if blockTypeCount == 0: break
  let orientationCount = blockTypeCount * orientationsPerType
  buildOrientations(blockTypeCount)
  sortOrientations(orientationCount)
  outputBuffer.add $tallestTower(orientationCount)
  outputBuffer.add '\n'
  flushOutput(false)
flushOutput(true)
```

The loop reads cases until zero or end of input. Each case emits one line, so output stays small. This costs one pass over all cases.

## Complexity

Costs use c cases and n orientations, where n is at most 90.

| Phase | Time | Space |
| --- | --- | --- |
| Input load | O(total input bytes) | O(total input bytes) |
| Orientation build | O(n) per case | O(n) |
| Sort | O(n²) per case | O(1) extra |
| Tower scan | O(n²) per case | O(1) extra |
| Output | O(c) bytes | O(1) beyond the block |

Total time is O(input + c n²) and total space is O(input + n). Enumerating every stack takes exponential time, so the scan replaces a search over all orders with one pass over 90 slots.

# IKEYB — I-Keyboard (SPOJ)

<https://www.spoj.com/problems/IKEYB/>

## Problem

Typing a letter on a phone keypad costs one press per position on its key. Assign letters to keys so a typed message costs as little as possible.

Read `t` cases. Each case gives `K`, `L`, the `K` key characters, the `L` letter characters, and `L` frequencies. Split the letters into consecutive groups, one group per key.

Print `Keypad #j:`, then `K` lines of `key: letters`, then a blank line. Cost ties go to the layout with more letters on the last key, then the key before it.

The bounds stay small in both dimensions:

| Quantity | Bound |
| --- | --- |
| Test cases `t` | about 2000 |
| Keys `K` | 1 to 90 |
| Letters `L` | `K` to 90 |
| Letter frequency | 1 to 100000 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The product `K * L` never exceeds 8100, so a quadratic table fits.

The sample case:

```
1
8 26
23456789
ABCDEFGHIJKLMNOPQRSTUVWXYZ
3371
589
1575
1614
6212
971
773
1904
2989
123
209
1588
1513
2996
3269
1080
121
2726
3083
4368
1334
518
752
427
733
871
```

```
Keypad #1:
2: ABCD
3: EFG
4: HIJK
5: LM
6: NOPQ
7: RS
8: TUV
9: WXYZ

```

## Idea

Cut the letter string into `K` consecutive blocks, like slicing a long ribbon. Prefix sums price any slice at once.

A dynamic program fills `minimumCost[k][l]`, the cheapest way to place the first `l` letters on `k` keys. Each state tries every possible split point. `bestSplitAt` saves the smallest split on a tie, which leaves the most letters on the last key.

Walking those saved splits backward fills every key in the required order.

Each state scans at most `L` splits, so one case costs O(K L^2). Listing all partitions takes exponential time.

## Why It Works

Five facts prove the program optimal and correctly ordered.

1. `prefixFrequency` sums frequencies up to a letter. `prefixWeighted` sums each frequency times its letter index.
2. The cost of block `k` through `l` is the weighted sum minus `(k - 1)` times the plain sum. The subtraction restarts positions at one on each key.
3. `minimumCost[k][l]` picks the smallest value of `minimumCost[k - 1][i] + segmentCost[i + 1][l]` over `i` from `k - 1` to `l - 1`.
4. The `infiniteCost` guard skips prefixes no key assignment can reach. Adding to such a state would overflow and create a false negative cost.
5. A strict `<` comparison keeps the smallest split on a tie. That choice maximizes the last key, and backtracking repeats it for earlier keys.

The tables and their roles:

| Term | Meaning |
| --- | --- |
| `minimumCost` | cheapest cost for the first `l` letters on `k` keys |
| `bestSplitAt` | smallest split point kept at each state |
| `segmentCost` | typing cost of one consecutive block |
| `prefixFrequency` | running sum of letter frequencies |
| `prefixWeighted` | running sum of frequency times letter index |
| `infiniteCost` | sentinel for unreachable states |

Every block price comes from two prefix entries, so no block is rescanned.

A script prices the sample layout key by key:

| Key | Letters | Cost |
| --- | --- | --- |
| 2 | ABCD | 15730 |
| 3 | EFG | 10473 |
| 4 | HIJK | 9087 |
| 5 | LM | 4614 |
| 6 | NOPQ | 13258 |
| 7 | RS | 8892 |
| 8 | TUV | 8590 |
| 9 | WXYZ | 7289 |

The costs sum to 77933, and no other layout beats it.

## Code

**Constants and tables.** Fixed arrays hold every DP state and prefix entry.

```nim
const maxKeyCount = 90
const maxLetterCount = 90
const flushBlockBytes = 1 shl 18
const firstDigitValue = 48
const infiniteCost = high(int64) div 4

var inputData = ""
var i = 0
var outputBuffer = ""

var minimumCost: array[0..maxKeyCount + 1, array[0..maxLetterCount + 1, int64]]
var bestSplitAt: array[0..maxKeyCount + 1, array[0..maxLetterCount + 1, int]]
var segmentCost: array[0..maxLetterCount + 1, array[0..maxLetterCount + 1, int64]]
var prefixFrequency: array[0..maxLetterCount + 1, int64]
var prefixWeighted: array[0..maxLetterCount + 1, int64]
var frequencyValues: array[0..maxLetterCount + 1, int64]
var keyCharacters: array[0..maxKeyCount + 1, char]
var letterCharacters: array[0..maxLetterCount + 1, char]
var groupStart: array[0..maxKeyCount + 1, int]
var groupEnd: array[0..maxKeyCount + 1, int]
```

The arrays reuse the same memory across all cases. `infiniteCost` leaves room to add a block price without overflow.

**Output helpers and scanners.** One buffer collects writes, and scanners read characters and integers.

```nim
proc flushOutput() =
  stdout.write outputBuffer
  outputBuffer.setLen 0

proc appendText(textValue: string) =
  outputBuffer.add textValue
  if outputBuffer.len >= flushBlockBytes:
    flushOutput()

proc appendCharacter(characterValue: char) =
  outputBuffer.add characterValue
  if outputBuffer.len >= flushBlockBytes:
    flushOutput()

proc nextInteger(): int =
  let dataLength = inputData.len
  while i < dataLength and inputData[i] != '-' and
      (inputData[i] < '0' or inputData[i] > '9'):
    inc i
  var isNegative = false
  if i < dataLength and inputData[i] == '-':
    isNegative = true
    inc i
  var numberValue = 0
  while i < dataLength and inputData[i] >= '0' and
      inputData[i] <= '9':
    numberValue = numberValue * 10 + (ord(inputData[i]) - firstDigitValue)
    inc i
  if isNegative:
    return -numberValue
  return numberValue

proc nextCharacter(): char =
  let dataLength = inputData.len
  while i < dataLength and inputData[i] <= ' ':
    inc i
  result = inputData[i]
  inc i
```

`flushOutput` writes one block and clears the string. `nextInteger` handles a minus sign before the digits. `nextCharacter` skips whitespace and returns one letter or key name.

**Prefix sums and block costs.** Two running sums price every consecutive block.

```nim
    prefixFrequency[0] = 0
    prefixWeighted[0] = 0
    for l in 1..letterCount:
      frequencyValues[l] = int64(nextInteger())
      prefixFrequency[l] = prefixFrequency[l - 1] + frequencyValues[l]
      prefixWeighted[l] = prefixWeighted[l - 1] +
          frequencyValues[l] * int64(l)

    for k in 1..letterCount:
      for l in k..letterCount:
        let frequencySum = prefixFrequency[l] - prefixFrequency[k - 1]
        let weightedSum = prefixWeighted[l] - prefixWeighted[k - 1]
        segmentCost[k][l] = weightedSum - int64(k - 1) * frequencySum
```

The inner loop visits `letterCount` times for each `k`. The offset `(k - 1)` restarts positions at one on each key. Every block cost takes constant time.

**Dynamic program.** The nested loops fill one state per key count and letter count.

```nim
    for k in 0..keyCount:
      for l in 0..letterCount:
        minimumCost[k][l] = infiniteCost
        bestSplitAt[k][l] = -1
    minimumCost[0][0] = 0
    for k in 1..keyCount:
      for l in k..letterCount:
        var chosenCost = infiniteCost
        var chosenSplit = -1
        for i in (k - 1)..(l - 1):
          if minimumCost[k - 1][i] >= infiniteCost:
            continue
          let candidateCost = minimumCost[k - 1][i] +
              segmentCost[i + 1][l]
          if candidateCost < chosenCost:
            chosenCost = candidateCost
            chosenSplit = i
        minimumCost[k][l] = chosenCost
        bestSplitAt[k][l] = chosenSplit
```

The scan visits `l - k + 1` split points per state. The guard skips unreachable prefixes. Strict comparison keeps the smallest tie split, so the last key grows first.

**Reconstruction and printing.** Saved splits are walked backward, then printed key by key.

```nim
    appendText("Keypad #")
    appendText($j)
    appendText(":\n")

    var remainingLetters = letterCount
    var k = keyCount
    while k >= 1:
      let i = bestSplitAt[k][remainingLetters]
      groupStart[k] = i + 1
      groupEnd[k] = remainingLetters
      remainingLetters = i
      dec k

    for l in 1..keyCount:
      appendCharacter(keyCharacters[l])
      appendText(": ")
      if groupStart[l] <= groupEnd[l]:
        for k in groupStart[l]..groupEnd[l]:
          appendCharacter(letterCharacters[k])
      appendText("\n")
    appendText("\n")

  flushOutput()
```

The first loop runs `keyCount` times. The empty-group check keeps the trailing space on an unused key. The second loop writes `K` lines and at most `L` letters.

## Complexity

Precomputation and the DP share the same quadratic shape.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(input bytes) | input buffer |
| Prefix and block costs | O(L^2) per case | O(L^2) table |
| Dynamic program | O(K L^2) per case | O(K L) tables |
| Reconstruction and output | O(L + K) per case | O(K) group arrays |

Constants cap `K` and `L` at 90, so each table stays small.

| Measure | Big O |
| --- | --- |
| Time | O(K L^2) per case |
| Space | O(K L) plus input and output buffers |

Direct enumeration examines every grouping of the letter sequence and grows exponentially.

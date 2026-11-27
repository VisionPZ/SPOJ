# RETO1 — Crazy Computer (SPOJ)

<https://www.spoj.com/problems/RETO1/>

## Problem

ZS Coder types words one at a time at recorded seconds. Suppose a word appears at second `B` after the previous word at second `A`. A gap `B - A` of at most `c` keeps the older words on screen and adds the new one. A gap greater than `c` clears everything first, and only the new word remains. Given all typing times, print how many words remain after the last one.

The first line holds `N` and `C`. The next line holds the `N` strictly increasing seconds. Print one positive integer.

| Item | Bound |
|---|---|
| Words `N` | 1 to 100000 |
| Delay `C` | 1 to 10<sup>9</sup> seconds |
| Typing second `t<sub>i</sub>` | 1 to 10<sup>9</sup> |
| Ordering | `t<sub>1</sub>` < `t<sub>2</sub>` < ... < `t<sub>N</sub>` |
| Judge limit | 1000 ms, 1536 MB |

The first sample input:

```
6 5
1 3 8 14 19 20
```

The first sample output:

```
3
```

The second sample input:

```
6 1
1 3 5 7 9 10
```

The second sample output:

```
2
```

## Idea

Think of a whiteboard that a helper wipes whenever too much time passes between notes. Only the notes written since the last wipe are still visible.

The program keeps a count instead of the words. It starts at one for the first word. For each later word it compares the gap with the delay. A large gap resets the count to one; a small gap adds one. Each word costs one comparison and one addition.

## Why It Works

1. The screen after any word depends only on the gap from the previous word.
2. A gap greater than `c` removes every older word, leaving only the new word.
3. A gap of at most `c` preserves the current words and adds the new word.
4. Word identities never matter, so a count describes the screen completely.
5. The answer is the length of the block after the last clearing gap.

| Term | Meaning |
|---|---|
| `wordCount` | number of typed words `N` |
| `delay` | the crazy delay `C` |
| `remainingCount` | words still visible after the current word |
| `previousTime` | second of the previous word |
| `currentTime` | second of the word being considered |

A script-generated trace of both samples:

```
C=5 gaps: 2, 5, 6, 5, 1 -> wipe at 14 -> words 14, 19, 20 -> 3
C=1 gaps: 2, 2, 2, 2, 1 -> wipe at 9 -> words 9, 10 -> 2
```

Both traced counts match the sample outputs.

## Code

**Input and scanner.** Read all lines once and scan integers by index.

```nim
const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner reads the two header values first, then the long time list. The buffer flushes every 128 KiB.

**Driver.** Reset the count at each clearing gap.

```nim
let wordCount = nextInt(inputData, scanPos)
let delay = nextInt(inputData, scanPos)
var remainingCount = 1
var previousTime = nextInt(inputData, scanPos)
for wordIndex in 1 ..< wordCount:
  let currentTime = nextInt(inputData, scanPos)
  if currentTime - previousTime > delay:
    remainingCount = 1
  else:
    remainingCount += 1
  previousTime = currentTime
appendOutput($remainingCount & "\n")
stdout.write outputBuffer
```

The first word starts the count at one. Only the previous second is kept, not the whole history.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | one input string |
| One word | one comparison and one update | O(1) |
| Output | one short write | one output string |

| Measure | Big O |
|---|---|
| Time | O(N + input size) |
| Space | O(1) beyond input |

Storing every visible word would use O(N) memory and would still only need a count. The program never revisits an earlier second.

# PONDO4 — Pondowo Four (SPOJ)
<https://www.spoj.com/problems/PONDO4/>

## Problem

A counter starts at zero. One word adds one to the counter, and another word multiplies the counter by three. Find the fewest words that produce a given positive integer n.

The only input line holds n. Print one integer, the minimum word count.

| Constraint | Value |
| --- | --- |
| Target n | 1 to 1000000000 |
| Judge time | 1000 ms |
| Judge memory | 1536 MB |

The two words are applied in any order, and only exact results count.

The statement sample follows byte for byte.

```
17
```

```
7
```

One optimal run adds, triples, adds, adds, triples, adds, adds.

## Idea

Work the number backwards, like rewinding a video of the count: undo additions by subtracting and undo triplings by dividing by three. When the current value divides by three, divide. When it does not, subtract the small remainder first. Each reverse step mirrors one spoken word, so the step count is the answer. A forward search over all counters up to n visits n states, while the reverse walk takes only a few dozen steps. Rewind n to zero with subtractions and divisions by three.

## Why It Works

1. The forward words are add one and multiply by three.
2. Their reverse forms are subtract one and divide by three.
3. Division by three is legal only when the current value is a multiple of three.
4. When division is legal, subtracting three times first would add three words before the same division.
5. When division is not legal, at least one subtraction is required before any division becomes legal.
6. Subtracting the remainder reaches the nearest lower multiple of three in the fewest steps.

The stored values are named below.

| Term | Meaning |
| --- | --- |
| `targetNumber` | the number to produce |
| `remaining` | current value during the reverse walk |
| `remainder` | remaining modulo three |
| `wordCount` | number of reverse steps taken so far |

Every loop iteration reduces `remaining`, so the walk always ends at zero.

A script check of the sample rewinds 17 to zero.

| Step | Value before | Action | Value after | Words |
| --- | --- | --- | --- | --- |
| 1 | 17 | subtract 2 | 15 | 2 |
| 2 | 15 | divide by 3 | 5 | 3 |
| 3 | 5 | subtract 2 | 3 | 5 |
| 4 | 3 | divide by 3 | 1 | 6 |
| 5 | 1 | subtract 1 | 0 | 7 |

The total of seven matches the sample. All values fit in `int64`, and the remainder is never negative.

## Code

**Input and scanner.** One line supplies the target number.

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

The scanner skips the trailing newline. It reads the one value into an integer.

**Buffered output.** A shared string holds the word count.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One final flush writes the answer. The buffer keeps output handling off the hot path.

**Reverse walk.** Each loop undoes one or several forward words.

```nim
let targetNumber = int64(nextInt(inputData, scanPos))
var remaining = targetNumber
var wordCount: int64 = 0
while remaining > 0:
  var remainder = remaining mod 3
  if remainder == 0:
    remaining = remaining div 3
    wordCount += 1
  else:
    remaining -= remainder
    wordCount += remainder
appendOutput($wordCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A remainder of one or two is paid off with that many subtractions. A zero remainder triggers one division. The count adds the exact number of words reversed.

## Complexity

The value drops by a factor of three on every second iteration or sooner.

| Phase | Time | Space |
| --- | --- | --- |
| read input | one number | one input string |
| reverse walk | O(log n) steps | two integers |
| output | one line | block buffer |

At most two subtractions precede each division, so the step count stays small.

| Measure | Big O |
| --- | --- |
| time | O(log n) |
| space | O(1) |

A forward breadth-first search explores up to n counters, while the reverse walk follows one path to zero. Working backwards with remainders gives the minimum word count directly.

# DHRODD — Total Odd V1 (SPOJ)

<https://www.spoj.com/problems/DHRODD/>

## Problem

Given one inclusive range `[L, R]`, report how many odd integers it contains. An odd integer is any integer not divisible by two.

The single input line holds `L` and `R`. The output is one integer on one line.

| Item | Bound |
|---|---|
| Lower bound `L` | 0 to 100000000 |
| Upper bound `R` | `L` to 100000000 |
| Judge limit | 2 s |
| Memory limit | 1536 MB |

Prefix counting beats enumerating up to 100000000 values.

The sample as printed in the statement:

```
2 3
```

```
1
```

## Idea

Counting odds in a range is like counting striped tiles between two floor marks. You read the stripe total at each mark and subtract.

The prefix `odd(n)` equals `(n + 1) div 2`. The answer is `odd(R) - (L div 2)`. Since `L div 2` equals `odd(L - 1)`, one subtraction handles the whole range.

Each case costs one division pair. A loop over every value would run up to 100000000 iterations and miss the limit.

## Why It Works

1. Among integers from 1 through `n`, exactly `(n + 1) div 2` are odd.
2. Removing the prefix before `L` leaves exactly the odds inside `[L, R]`.
3. `odd(L - 1)` equals `L div 2`, so no separate prefix routine is needed.
4. Values stay below 100000001, so machine integers hold every intermediate.

| Term | Meaning |
|---|---|
| `leftBound` | first endpoint `L` |
| `rightBound` | second endpoint `R` |
| `oddCount` | number of odd values in the range |
| `nextInt` | hand scanner over the input buffer |

`gen.py` prints this trace while building the files:

```
trace: [2,3] span 2, even span, even start -> 1
```

The trace agrees with the sample, since `4 div 2 - 2 div 2` equals one.

## Code

**Integer scanner.** Reads decimal values by byte index from the buffered input.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The scanner skips whitespace without copying tokens. `firstDigitValue` converts a digit byte into its value. Cost is one pass over two numbers.

**Driver and prefix formula.** Buffers input, computes the count, and writes one line.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var scanPos = 0
let leftBound = nextInt(inputData, scanPos)
let rightBound = nextInt(inputData, scanPos)
let oddCount = (rightBound + 1) div 2 - leftBound div 2
appendOutput($(oddCount))
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

`scanPos` advances only forward. Extra input bytes are ignored, as the statement allows one line. The final flush emits the answer.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Count | two divisions | none |
| Output | one buffered line | one buffer |

The arithmetic never depends on the range width.

| Measure | Big O |
|---|---|
| Time | O(input bytes) |
| Space | O(input bytes) |

Testing each integer would take O(R - L + 1) time, up to 100000000 steps. Prefix counting finishes in constant time.

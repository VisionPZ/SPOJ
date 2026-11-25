# SMPSUM — Iterated sums (SPOJ)

<https://www.spoj.com/problems/SMPSUM/>

## Problem

Add the squares of every integer from `a` through `b`, endpoints included, and print the single total.

Input holds two integers `a` and `b` separated by a space. Output holds one line with the sum of `a*a`, `(a+1)*(a+1)`, and so on up to `b*b`.

| Item | Bound |
|---|---|
| Lower value `a` | 1 <= a <= b |
| Upper value `b` | b <= 100 |
| Terms added | at most 100 |
| Judge limit | 1000 ms, 1536 MB |

Sample 1:

```
1 4
```

```
30
```

Sample 2:

```
5 6
```

```
61
```

## Idea

Think of adding up square tiles whose side lengths run from `a` to `b`.

The program reads the whole input into one string, scans the two integers by index, and walks the range once. Each step adds `currentNumber * currentNumber` to one accumulator.

One multiplication and one addition happen per integer, so at most 100 steps. A closed-form formula would skip the loop, but the range is already tiny.

## Why It Works

1. The scan reads exactly two integers, which are the inclusive ends of the range.
2. The walk starts at `lowerBound` and stops after `upperBound`, so each required square is added once.
3. `sumOfSquares` starts at zero, so it holds the running total when the loop ends.
4. The largest possible total is 338350, which fits an `int`.

| Term | Meaning |
|---|---|
| `lowerBound` | first integer whose square is added |
| `upperBound` | last integer whose square is added |
| `currentNumber` | the integer whose square is being added |
| `sumOfSquares` | running total of the squares |

The loop visits the range in order, and the accumulator keeps the total.

A traced run of the first sample, produced by the generator:

```
lowerBound=1 upperBound=4
currentNumber 1 -> sumOfSquares 1
currentNumber 2 -> sumOfSquares 5
currentNumber 3 -> sumOfSquares 14
currentNumber 4 -> sumOfSquares 30
append "30" then newline
```

The trace ends at 30, which matches the sample output.

## Code

**Constants.** The digit byte offset and the output block size.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
```

`firstDigitValue` is the byte of `0`. The block size caps memory spent on output before a write.

**Input read.** Every line is appended to one string.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

`readLine` works on the judge compiler. Extra blank lines become whitespace inside the buffer.

**Digit scanner.** Each call advances `scanPos` past one integer.

```nim
var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The `var` parameter keeps the position between calls. No substring or parse call is needed.

**Output buffer.** Appends collect bytes and flush a full block.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`setLen 0` reuses the same storage after a flush. One short answer never fills a block.

**Driver.** Reads the two ends and walks the range.

```nim
let lowerBound = nextInt(inputData, scanPos)
let upperBound = nextInt(inputData, scanPos)
var sumOfSquares = 0
var currentNumber = lowerBound
while currentNumber <= upperBound:
  sumOfSquares += currentNumber * currentNumber
  currentNumber += 1
appendOutput($(sumOfSquares))
outputBuffer.add '\n'
stdout.write outputBuffer
```

The loop bound is at most 100, and the accumulator stays in `int`. The final write emits the one answer line.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Two scans | one pass over the value digits | constant |
| Range walk | one multiply and add per integer in the range | constant |
| Output | one buffered write | one buffer |

The range length bounds the arithmetic work.

| Measure | Big O |
|---|---|
| Time | O(N) for N input bytes plus O(b - a + 1) for the walk |
| Space | O(N) for the input buffer |

A formula using `k(k+1)(2k+1)/6` would need O(1) steps instead of O(b - a + 1), but the walk costs at most 100 steps here.

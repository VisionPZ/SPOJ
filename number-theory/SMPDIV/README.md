# SMPDIV — Divisibility (SPOJ)

<https://www.spoj.com/problems/SMPDIV/>

## Problem

List every integer strictly between 1 and `n` that is divisible by `x` but not divisible by `y`.

Input starts with a test count `t`. Each of the next `t` lines gives three integers `n x y`. Each output line holds the requested numbers in ascending order, separated by single spaces; an empty result gives an empty line.

| Item | Bound |
|---|---|
| Test cases `t` | t < 100 |
| Upper bound `n` | 1 < ai < n < 100000 |
| Divisor relation | x < n, and x is not divisible by y |
| Judge limit | 1000 ms, 1536 MB |

Sample:

```
2
7 2 4
35 5 12
```

```
2 6
5 10 15 20 25 30
```

## Idea

Think of walking down a street and stopping only at houses whose numbers are multiples of `x`.

The program reads all lines into one string and scans each triple by index. It steps from the first multiple of `divisor` above 1 up to `limitValue - 1`. Each candidate that passes the `excludedDivisor` test goes into one output buffer.

One modulo test happens per multiple, so a case costs about `n / x` steps. Visiting every integer in the range would cost `n` steps instead.

## Why It Works

1. Stepping by `divisor` from its first multiple above 1 visits every allowed candidate once, in ascending order.
2. The condition `candidate > 1` enforces the strict lower bound from the statement.
3. The condition `candidate < limitValue` enforces the strict upper bound from the statement.
4. The test `candidate mod excludedDivisor != 0` removes exactly the candidates divisible by `y`.
5. `hasPrevious` inserts a space only before a second or later value, so no line ends with a space.

| Term | Meaning |
|---|---|
| `limitValue` | the `n` of one case, an excluded upper bound |
| `divisor` | the `x` of one case, the step size |
| `excludedDivisor` | the `y` of one case, the rejected divisor |
| `candidate` | the next multiple of `divisor` under test |
| `hasPrevious` | true after the first emitted value of the line |

The step controls which values are seen, and the modulo test controls which are printed.

A traced run of the first sample case, produced by the generator:

```
limitValue=7 divisor=2 excludedDivisor=4
candidate 2 -> 2 mod 4 = 2, emit "2"
candidate 4 -> 4 mod 4 = 0, skip
candidate 6 -> 6 mod 4 = 2, emit " 6"
candidate 8 -> 8 >= 7, stop
line "2 6"
```

The trace matches the first sample output line.

## Code

**Constants.** The digit byte offset and the output block size.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
```

`firstDigitValue` is the byte of `0`. The block size bounds buffer memory before a write.

**Input read.** Lines are appended to one string.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

`readLine` works on the judge compiler. Padded or blank lines turn into whitespace in the buffer.

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

The `var` parameter keeps the position between calls. A digit byte becomes `int(data[pos]) - 48`.

**Output buffer.** Appends collect bytes and flush a full block.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`setLen 0` reuses the storage after a write. Large answers span several blocks, each flushed once.

**Case loop.** One stepped walk and one line per test case.

```nim
let caseCount = nextInt(inputData, scanPos)
var caseIndex = 0
while caseIndex < caseCount:
  let limitValue = nextInt(inputData, scanPos)
  let divisor = nextInt(inputData, scanPos)
  let excludedDivisor = nextInt(inputData, scanPos)
  var candidate = (1 + divisor) div divisor * divisor
  var hasPrevious = false
  while candidate < limitValue:
    if candidate > 1 and candidate mod excludedDivisor != 0:
      if hasPrevious:
        appendOutput(" ")
      appendOutput($(candidate))
      hasPrevious = true
    candidate += divisor
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
```

`div` and `*` are left associative, so the start is the first multiple above 1. The newline after each case also covers an empty line.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Case scan | one pass over three integers per case | constant |
| Stepped walk | one modulo test per multiple below `n` | constant |
| Output | one write per 128 KiB block | one buffer |

The count of multiples, not the value of `n`, drives the work per case.

| Measure | Big O |
|---|---|
| Time | O(N) input plus O(sum of n / x) tests over all cases |
| Space | O(N) for the input buffer plus one output block |

Filtering every integer from 2 to `n - 1` costs O(n) per case instead of O(n / x), and prints the same numbers.

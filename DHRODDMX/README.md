# DHRODDMX — Total Odd V2 (SPOJ)

<https://www.spoj.com/problems/DHRODDMX/>

## Problem

For each test case, report how many odd integers lie inside the inclusive range `[L, R]`. An odd integer is any integer not divisible by two.

The first input line holds the case count `T`. Each following line holds one pair `L`, `R`. Print one answer per case.

| Item | Bound |
|---|---|
| Test count `T` | 1 to 10 |
| Endpoints `L`, `R` | 1 to 1000000000000000000 |
| Judge limit | 1 s |
| Memory limit | 1536 MB |

Prefix counting is required because enumeration cannot cover 10^18 values.

The sample as printed in the statement:

```
3
1 1
1 3
2 3
```

```
1
2
1
```

## Idea

Prefix counting is like reading an odometer at two road markers and subtracting. You never walk the road between them.

The prefix `odd(n)` equals `(n + 1) div 2`. The answer is `odd(R) - (L div 2)`, because `L div 2` is `odd(L - 1)`.

Every endpoint reaches 10^18, so the scanner and all arithmetic use 64-bit integers. Each case costs two divisions and one subtraction.

## Why It Works

1. Among integers from 1 through `n`, exactly `(n + 1) div 2` are odd.
2. Removing the prefix before `L` leaves the odds inside `[L, R]`.
3. `odd(L - 1)` equals `L div 2`, so one subtraction is enough.
4. `R + 1` stays below 2^63, so 64-bit signed arithmetic holds it.
5. At most ten cases keep the output buffer far below 128 KiB.

| Term | Meaning |
|---|---|
| `caseCount` | number of ranges to process |
| `leftBound` | lower endpoint `L` of one case |
| `rightBound` | upper endpoint `R` of one case |
| `nextInt64` | hand scanner returning a 64-bit value |

`gen.py` prints this trace while building the files:

```
trace: [1,1] span 1, odd span, odd start -> 1
```

The trace matches the first sample answer.

## Code

**Wide integer scanner.** Reads 64-bit decimal values by byte index.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

proc nextInt64(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value
```

Each digit multiplies an `int64` accumulator by ten. The position moves forward only. No token string is allocated.

**Case loop.** Buffers input, applies the prefix formula, and emits one line per case.

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
let caseCount = nextInt64(inputData, scanPos)
for _ in 0..<caseCount:
  let leftBound = nextInt64(inputData, scanPos)
  let rightBound = nextInt64(inputData, scanPos)
  let oddCount = (rightBound + 1) div 2 - leftBound div 2
  appendOutput($(oddCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

`caseCount` controls the loop, so stray bytes are harmless. `$(oddCount)` formats a 64-bit value without a parse call. The final flush writes all ten lines.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Count per case | two 64-bit divisions | none |
| Output | one final write | one buffer |

No step depends on the numeric size of the endpoints.

| Measure | Big O |
|---|---|
| Time | O(input bytes + T) |
| Space | O(input bytes) |

Enumerating the range would take O(R - L + 1) time, impossible at 10^18. Prefix counting handles each case in constant time.

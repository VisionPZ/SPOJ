# MOZSALY — Sharmeen And Leap Year (SPOJ)

<https://www.spoj.com/problems/MOZSALY/>

## Problem

Sharmeen checks a year with three ordered checks. Failing the divide-by-4 check ends the program at step 1. Passing 4 but failing the divide-by-100 check ends it at step 2. Every remaining year ends at step 3. Print the step where the program stops.

One integer year with 0 ≤ year ≤ 10⁸ arrives on stdin. Print the step number followed by a newline.

| Item | Bound |
|---|---|
| Year n | 0 ≤ n ≤ 10⁸ |
| Instances | one per input file |
| Judge limit | 1000 ms, 1536 MB |

The first failing check fixes the answer.

The sample case:

```
2012
```

```
2
```

## Idea

Walk the checks in order and stop at the first one that ends the program. Think of a corridor with three locked doors: you pass doors until one closes the way. Each check needs one remainder, so total time is constant. Testing every earlier year costs O(n) work and adds nothing. Apart from input bytes, the whole computation is O(1).

## Why It Works

1. Step 1 stops exactly when 4 does not divide the year.
2. Step 2 stops when 4 divides the year but 100 does not.
3. Step 3 stops the program for every remaining year.
4. The year 0 is divisible by 4, 100, and 400, so step 3 handles it.

| Term | Meaning |
|---|---|
| `year` | the integer read from input |
| `mod` | Nim's integer remainder operator |
| divide by 4 | the condition tested at step 1 |
| divide by 100 | the condition tested at step 2 |

Three remainders replace a calendar or a range scan.

A script-traced example from `gen.py`:

```
2012 passes the divide by 4 check
2012 fails the divide by 100 check
the program halts at step 2
```

The trace matches the sample output of 2.

## Code

**Input and scanner.** This block loads stdin and reads one integer by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value
```

One readLine loop stores the whole input.
The scanner skips separators and builds the value.
The scan costs one pass over the digits.

**Buffered output.** This block collects answer bytes before writing.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after reaching 128 KiB.
One final write emits any remaining bytes.
Each append runs in constant time.

**Step chain and final flush.** This block applies the three checks in order.

```nim
let year = nextInt(inputData, scanPos)
if year mod 4 != 0:
  appendOutput("1\n")
elif year mod 100 != 0:
  appendOutput("2\n")
else:
  appendOutput("3\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The branches mirror the stated checks.
The order matters because step 1 wins first.
The final write flushes the buffer at exit.

## Complexity

The cost splits into one input read, up to three remainders, and one write.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Checks | at most three O(1) tests | constant |
| Output | one write per 128 KiB block | block buffer |

Each phase stays within the small bound.

| Measure | Big O |
|---|---|
| Time | O(L) for L input bytes |
| Space | O(L) for the input string |

Scanning all years below n costs O(n) work.
Three remainders replace that scan.

# SMPWOW — Wow (SPOJ)

<https://www.spoj.com/problems/SMPWOW/>

## Problem

Read one positive integer and print the word made from one `W`, that many `o` letters, and one `w`.

Input holds a single integer `x`. Output holds one line: `W`, then `x` copies of `o`, then `w`, then a newline.

| Item | Bound |
|---|---|
| Input value `x` | 0 < x < 50 |
| Output length | x + 2 characters |
| Judge limit | 1000 ms, 1536 MB |

Sample 1:

```
1
```

```
Wow
```

Sample 2:

```
7
```

```
Wooooooow
```

## Idea

Think of a name badge: a capital letter, a row of circles, and a small closing letter.

The program reads the whole input into one string, scans the integer by index, and appends the three parts to one output buffer. A loop adds one `o` per requested copy.

Each copy costs one buffer append, so the work equals the output length. Splitting tokens into a list first would allocate objects for a single number.

## Why It Works

1. The input contains one integer, so the scanner reads one value and ignores surrounding whitespace.
2. The loop counts from zero up to `repeatCount`, which appends exactly `repeatCount` copies of `o`.
3. The leading `W` and trailing `w` are outside the loop, so they appear once each.
4. The final write flushes the buffer, which holds the whole short answer.

| Term | Meaning |
|---|---|
| `inputData` | the whole input read into one string |
| `scanPos` | index of the next character to inspect |
| `repeatCount` | the value read from the input |
| `outputBuffer` | the single string holding the answer |

The three parts decide the answer, and the count decides only the middle row.

A traced run of the second sample, produced by the generator:

```
count = 7
"o" * 7 -> "ooooooo"
"W" + "ooooooo" + "w" -> "Wooooooow"
append newline -> "Wooooooow\n"
```

The trace matches the sample output byte for byte.

## Code

**Constants.** The digit byte offset and the output block size.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
```

`firstDigitValue` is the byte of `0`. A 128 KiB block is large enough for this one short answer.

**Input read.** Lines are appended to one string.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

`readLine` is available on the judge compiler. Blank and padded lines become harmless whitespace in the buffer.

**Digit scanner.** One pass over the digits of the value.

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

The `var` parameter keeps the scan position across calls. A digit byte becomes `int(data[pos]) - 48`.

**Output buffer.** Appends collect bytes and flush a full block.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`setLen 0` clears the buffer while reusing its storage. The block guard avoids a write per character.

**Driver.** Reads the count and emits the word.

```nim
let repeatCount = nextInt(inputData, scanPos)
appendOutput("W")
var charIndex = 0
while charIndex < repeatCount:
  appendOutput("o")
  charIndex += 1
appendOutput("w")
outputBuffer.add '\n'
stdout.write outputBuffer
```

The loop bound is `repeatCount`, which is at most 49. The final write covers the tail of the buffer.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Digit scan | one pass over the value digits | constant |
| Output | one loop over `x` copies, one buffered write | one buffer |

The input size and the count bound the whole run.

| Measure | Big O |
|---|---|
| Time | O(N) for N input bytes plus O(x) appended characters |
| Space | O(N) for the input buffer plus O(x) for partial output |

Writing each character straight to the stream would issue up to 51 writes. One buffer keeps the write count at one.

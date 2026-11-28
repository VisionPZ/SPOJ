# BSCXOR — XOR (SPOJ)

<https://www.spoj.com/problems/BSCXOR/>

## Problem

Two switches are either off or on. The answer is on when exactly one of them is on.

Input: two integers `p` and `q`, each 0 or 1, separated by a space. Output: their XOR, 0 or 1, on one line.

| Item | Bound |
|---|---|
| First logic value `p` | 0 or 1 |
| Second logic value `q` | 0 or 1 |
| Judge limit | 1000 ms, 1536 MB |

The sample, verbatim:

```
1 1
```

```
0
```

## Idea

Think of a light controlled by two switches wired so that matching positions leave it dark. Direct truth-table evaluation reads the two bits and compares them.

One comparison settles the answer, so the cost per value is constant. Building a truth table or using a bit operator would add work without changing the result.

The equality test covers all four input pairs.

## Why It Works

1. Equal bits give XOR zero, so the code prints `0`.
2. Different bits give XOR one, so the code prints `1`.
3. Both input values lie in `{0, 1}`, so no other case exists.
4. The newline is appended after the digit, matching the sample bytes.

| Term | Meaning |
|---|---|
| `firstValue` | the logic value `p` |
| `secondValue` | the logic value `q` |
| `outputBuffer` | the single string holding the answer |

The equality test implements the whole truth table.

A traced run of the sample, produced by the generator:

```
p 1, q 1, different 0
answer 0
```

The trace matches the sample output.

## Code

**Constants and input read.** One string holds every input line.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

The digit offset is the byte of `0`. The block size bounds the output buffer.

**Digit scanner.** Each call advances the shared scan position past one integer.

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

The `var` parameter keeps the position between calls. Both values are nonnegative.

**Output buffer.** Appends collect bytes and write one block at a time.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`setLen 0` reuses the storage after a write.

**Truth table.** One equality test chooses the printed digit.

```nim
let firstValue = nextInt(inputData, scanPos)
let secondValue = nextInt(inputData, scanPos)
if firstValue == secondValue:
  appendOutput("0")
else:
  appendOutput("1")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Both readings consume the two integers in order. The final write covers the answer line.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the lines | input bytes |
| Digit scan | one pass over two integers | constant |
| Truth table | one equality test | constant |
| Output | one write per block | one buffer |

No phase depends on a size parameter.

| Measure | Big O |
|---|---|
| Time | O(1) |
| Space | O(1) plus one output block |

A table lookup over all four pairs would also cost constant work but needs extra storage.

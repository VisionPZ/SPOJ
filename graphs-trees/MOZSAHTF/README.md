# MOZSAHTF — Sharmeen And Her Two Friends (SPOJ)

<https://www.spoj.com/problems/MOZSAHTF/>

## Problem

Sharmeen hides two integers and reveals only their difference. Samira picks one odd integer and one even integer. Rabeya picks two integers of equal parity. Given the difference alone, name the friend who could have chosen the pair.

One integer n, the difference, arrives on stdin. Print `Samira` or `Rabeya` on its own line.

| Item | Bound |
|---|---|
| Difference n | 0 ≤ n ≤ 100000 |
| Instances | one per input file |
| Judge limit | 1000 ms, 1536 MB |

The difference carries all the parity information needed.

The sample case:

```
5
```

```
Samira
```

## Idea

An odd difference forces one even and one odd number, so Samira wins. An even difference forces matching parity, so Rabeya wins. Think of two light switches: flipping one changes the lamp, while flipping neither or both leaves it unchanged. One remainder test settles the case. Enumerating candidate pairs costs O(n) work for no gain. Each input costs constant time, so total time is O(1) apart from reading bytes.

## Why It Works

1. Subtracting two integers of equal parity always gives an even result.
2. Subtracting integers of opposite parity always gives an odd result.
3. The bounds include n = 0, which is even and therefore means Rabeya.
4. The parity of n identifies the friend without reconstructing the pair.

| Term | Meaning |
|---|---|
| `difference` | the integer n read from input |
| parity | whether an integer is even or odd |
| `mod` | Nim's integer remainder operator |
| equal parity | both chosen integers even, or both odd |

Only the remainder after division by two matters.

A script-traced example from `gen.py`:

```
5 minus pairs of 2 leaves remainder 1
mixed parity pair means Samira
0 minus pairs of 2 leaves remainder 0
same parity pair means Rabeya
```

The trace gives Samira for 5, matching the sample output.

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

**Decision and final flush.** This block picks the friend and writes the answer.

```nim
let difference = nextInt(inputData, scanPos)
if difference mod 2 == 1:
  appendOutput("Samira\n")
else:
  appendOutput("Rabeya\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

One remainder test chooses the name.
The empty buffer is written at exit.
The work here is constant.

## Complexity

The program reads once, decides once, and writes once.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Decision | O(1) remainder test | constant |
| Output | one write per 128 KiB block | block buffer |

Every phase stays below the small input size.

| Measure | Big O |
|---|---|
| Time | O(L) for L input bytes |
| Space | O(L) for the input string |

Enumerating candidate pairs costs O(n) work, so the parity test replaces it.

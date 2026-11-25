# ICODER — Instruction Decoder (SPOJ)

<https://www.spoj.com/problems/ICODER/>

## Problem

A 16-bit register starts at an unknown value. A code segment applies ADD and MUL instructions modulo 65536. Report how many different final values are possible over all starting values.

Each case starts with N, followed by N lines of the form `ADD X` or `MUL X`. A line holding 0 ends the input. Print one count per case.

| item | bound |
|---|---|
| instructions per case N | 1 to 100000 |
| operand X | 0 to 65535 |
| register size | 16 bits, modulus 65536 |
| judge limit | 1000 ms, 1536 MB |

The factors of two in the multipliers drive the answer.

Sample input:

```
1
ADD 3
1
MUL 0
5
MUL 3
ADD 4
MUL 5
ADD 3
MUL 2
8
ADD 32
MUL 5312
ADD 7
MUL 7
ADD 32
MUL 5312
ADD 7
MUL 7
0
```

Sample output:

```
65536
1
32768
16
```

## Idea

A multiplication by an even number folds the possible values onto fewer residues, like folding a strip of paper and marking only every second line. The reachable set stays one residue class modulo a power of two. Each ADD shifts that residue, and each MUL doubles its modulus by the number of trailing zeros in the operand. The count is 65536 divided by that modulus. Trying every starting register value would cost 65536 times more work per case. The residue walk handles each instruction in constant time.

## Why It Works

1. Initially every register value is possible, so the step is 1.
2. ADD X shifts every reachable value by the same amount and leaves the step unchanged.
3. MUL X maps a residue class modulo d onto a residue class modulo d times the greatest power of two dividing X, capped at 65536.
4. The residue after MUL X is the old residue times X, reduced modulo the new step.
5. The number of values in one residue class modulo d is 65536 divided by d.
6. A zero operand fixes the register at one value.

| term | meaning |
|---|---|
| `stepExponent` | exponent of the current power-of-two step |
| `residue` | common residue of all reachable values |
| `trailingZeros` | exponent of two in the current multiplier |
| `possibleValues` | number of reachable final values |

The cap at 16 keeps the step inside the register size.

A script trace of the fourth sample case gives these numbers:

```
ADD 32    multiplier 1     gcd 1
MUL 5312  multiplier 5312  gcd 64
MUL 7     multiplier 37184 gcd 64
MUL 5312  multiplier 61440 gcd 4096
MUL 7     multiplier 36864 gcd 4096
answer 65536 / 4096 = 16
```

The script value 16 matches the printed sample answer.

## Code

**Input and scanner.** The reader loads all cases, and the scanner skips instruction words.

```nim
const flushBlockBytes = 1 shl 17
const registerBits = 16
const registerModulus = 1 shl registerBits

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

proc nextOperation(data: string, pos: var int, isMultiply: var bool, operand: var int) =
  while pos < data.len and (data[pos] < 'A' or data[pos] > 'Z'):
    pos += 1
  if pos >= data.len:
    isMultiply = false
    operand = 0
    return
  isMultiply = data[pos] == 'M'
  operand = nextInt(data, pos)
```

The uppercase letter selects MUL or ADD.
The number scanner then reads the operand.
No line-by-line parsing is needed.

**Output buffer.** One buffer collects the counts.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes at 131072 bytes.
A final write clears any remainder.
No write happens per instruction.

**Case loop.** The driver walks instructions and tracks the residue step.

```nim
while true:
  let instructionCount = nextInt(inputData, scanPos)
  if instructionCount == 0:
    break
  var residue: int64 = 0
  var stepExponent = 0
  for instructionIndex in 0 .. instructionCount - 1:
    var isMultiply = false
    var operand = 0
    nextOperation(inputData, scanPos, isMultiply, operand)
    if isMultiply:
      var trailingZeros = 0
      var factor = operand
      while trailingZeros < registerBits and factor mod 2 == 0:
        trailingZeros += 1
        factor = factor div 2
      stepExponent = stepExponent + trailingZeros
      if stepExponent > registerBits:
        stepExponent = registerBits
      residue = (residue * int64(operand)) mod int64(registerModulus)
    else:
      residue = (residue + int64(operand)) mod int64(registerModulus)
  let possibleValues = int64(1) shl (registerBits - stepExponent)
  appendOutput($possibleValues)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The trailing-zero loop stops after 16 steps.
The exponent caps at 16 for a zero multiplier.
Shifting one by the remaining bits gives the count.

## Complexity

Each instruction takes a constant number of steps.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| instruction walk | one pass over instructions | fixed state |
| output | one buffered write per block | block buffer |

The instruction walk dominates every case.

| measure | Big O |
|---|---|
| time | O(N) per case |
| space | O(1) beyond the input string |

Simulating all 65536 starting values would cost far more per instruction.
This walk keeps long segments short.

# MMFBTEAM — Big team formation (SPOJ)

<https://www.spoj.com/problems/MMFBTEAM/>

## Problem

A coach owns n players and must form one team.
A team is a subset with at least two players.
One player is captain, a different player is keeper, and roles are distinct.
Count the possible teams modulo 1 000 000 007.
Each input line holds one n, and a line containing 0 ends the input.

| Item | Bound |
|---|---|
| Players | 2 ≤ n ≤ 10³⁰ |
| Modulus | 1 000 000 007 |
| Terminator | n = 0 |
| Judge limit | 2500 ms, 1536 MB |

The 30-digit bound rules out any loop over n.

The sample case:

```
2
3
0
```

```
2
12
```

## Idea

Choose the captain and keeper, then choose any subset of the other players.
The count is n(n − 1)2ⁿ⁻² modulo the prime.
Split the decimal digits of n into groups of five.
Two precomputed tables map each group and its position to the contribution it makes to n modulo M and to 2ⁿ modulo M.
Each input number then costs one table lookup per group, with no exponentiation and no allocation.

## Why It Works

1. Captain and keeper are distinct players, so role order yields n(n − 1) pairs.
2. The remaining n − 2 players each join or stay out, giving 2ⁿ⁻² subsets.
3. The modulus M is prime, so Fermat's theorem gives 2ᴹ⁻¹ = 1 modulo M.
4. Therefore 2ⁿ depends only on n modulo M − 1, and 2ⁿ⁻² equals 2ⁿ times the inverse of 4 modulo M.
5. That inverse is 250000002, so the answer is n(n − 1) · 2ⁿ · 250000002 modulo M.
6. Writing n in five-digit blocks gives n = Σ cⱼ · 10⁵ʲ. Thus n modulo M is the sum of cⱼ · 10⁵ʲ modulo M, and 2ⁿ is the product of 2^(cⱼ · 10⁵ʲ) modulo M.
7. The tables store both contributions for every group value at every position, so each group needs only two lookups.
8. Table rows are built by repeated addition and multiplication; the only modular power call builds the eight row steps once.
9. Input arrives in one bulk read, digits are consumed in place from right to left, and answer digits go straight into a fixed output buffer.

| Term | Meaning |
|---|---|
| `answerModulus` | the prime 1 000 000 007 |
| `quarterModulus` | inverse of 4 modulo M |
| `chunkBase` | 10⁵, the number of values in one table row |
| `maxChunks` | highest group index, covering 40 digits |
| `remainders` | cⱼ · 10⁵ʲ modulo M for each group value |
| `powers` | 2^(cⱼ · 10⁵ʲ) modulo M for each group value |
| `powerMod` | binary modular exponentiation, used only for the row steps |

Eight groups cover up to 40 digits, more than the 31 digits of 10³⁰.

A script-traced example from `gen.py`:

```
2 2
3 12
4 48
```

Brute-force subset counts match the folded computation.

## Code

**Constants, bulk input, and modular power.** This block reads stdin in one call and defines the power routine used to build table steps.

```nim
const firstDigitValue = 48
const answerModulus = 1000000007
const quarterModulus = 250000002
const chunkBase = 100000
const maxChunks = 7
const flushBlockBytes = 1 shl 16

var inputData = readStreamBytes()

proc powerMod(base: int64, exponent: int64): int64 =
  var productValue: int64 = 1
  var factor = base
  var power = exponent
  while power > 0:
    if (power and 1) == 1:
      productValue = productValue * factor mod int64(answerModulus)
    factor = factor * factor mod int64(answerModulus)
    power = power div 2
  return productValue
```

One read loads the whole input.
The power routine runs only while the tables are built, never per test case.

**Table construction.** This block fills the remainder and power tables once.

```nim
var remainders: array[0..maxChunks, array[0..chunkBase - 1, int32]]
var powers: array[0..maxChunks, array[0..chunkBase - 1, int32]]

var remainderStep: int64 = 1
var powerStep: int64 = 2
for j in 0 .. maxChunks:
  var remainderValue: int64 = 0
  var powerValue: int64 = 1
  for c in 0 .. chunkBase - 1:
    remainders[j][c] = int32(remainderValue)
    powers[j][c] = int32(powerValue)
    remainderValue += remainderStep
    if remainderValue >= int64(answerModulus):
      remainderValue -= int64(answerModulus)
    powerValue = powerValue * powerStep mod int64(answerModulus)
  remainderStep = remainderStep * int64(chunkBase) mod int64(answerModulus)
  powerStep = powerMod(powerStep, int64(chunkBase))
```

Each row advances by one step per entry, so building a row needs additions and multiplications only.
The step for the next row is raised to the fifth power of ten to move the group position.

**Buffered output.** This block writes answer digits directly into one fixed buffer.

```nim
var outputBuffer = newString(flushBlockBytes)
var outputLength = 0
var numberDigits: array[0..15, byte]

proc putNumber(v: int64) =
  if outputLength + 16 > flushBlockBytes:
    stdout.write outputBuffer[0 ..< outputLength]
    outputLength = 0
  var x = v
  var k = 0
  if x == 0:
    numberDigits[0] = byte(firstDigitValue)
    k = 1
  else:
    while x > 0:
      numberDigits[k] = byte(firstDigitValue) + byte(x mod 10)
      x = x div 10
      k += 1
  while k > 0:
    k -= 1
    outputBuffer[outputLength] = char(numberDigits[k])
    outputLength += 1
  outputBuffer[outputLength] = '\n'
  outputLength += 1
```

One bounds check per answer reserves room for the digits and the newline.
The buffer flushes a filled block with a single write.

**Scanning and answer loop.** This block consumes each token right to left and emits its answer.

```nim
var scanPos = 0
let inputLength = inputData.len

while true:
  while scanPos < inputLength and inputData[scanPos] <= ' ':
    scanPos += 1
  if scanPos >= inputLength:
    break
  var tokenEnd = scanPos
  while tokenEnd < inputLength and inputData[tokenEnd] > ' ':
    tokenEnd += 1
  scanPos = tokenEnd
  var readPos = tokenEnd - 1
  var nonzero = false
  var valueMod: int64 = 0
  var powerValue: int64 = 1
  var chunkIndex = 0
  while readPos >= 0 and inputData[readPos] > ' ':
    var chunk: int32 = 0
    var multiplier: int32 = 1
    var taken = 0
    while taken < 5 and readPos >= 0 and inputData[readPos] > ' ':
      let digit = byte(inputData[readPos]) - byte(firstDigitValue)
      if digit != 0:
        nonzero = true
      chunk += int32(digit) * multiplier
      multiplier *= 10
      dec readPos
      inc taken
    valueMod += int64(remainders[chunkIndex][chunk])
    if valueMod >= int64(answerModulus):
      valueMod -= int64(answerModulus)
    powerValue = powerValue * int64(powers[chunkIndex][chunk]) mod int64(answerModulus)
    inc chunkIndex
  if not nonzero:
    break
  var previous = valueMod - 1
  if previous < 0:
    previous += int64(answerModulus)
  let orderedPairs = valueMod * previous mod int64(answerModulus)
  let doubling = powerValue * int64(quarterModulus) mod int64(answerModulus)
  putNumber(orderedPairs * doubling mod int64(answerModulus))

stdout.write outputBuffer[0 ..< outputLength]
```

Five digits are folded into one group from the right.
A token of all zeroes is the terminator and stops the loop before any answer is written.
The final write flushes the remainder of the buffer at end of input.

## Complexity

The cost splits into table construction, input, group lookups, and output.

| Phase | Time | Space |
|---|---|---|
| Table build | O(maxChunks · chunkBase) once | two small int32 tables |
| Input read | one pass over input bytes | input bytes |
| Digit folds | O(P) digits for P total digits | no per-case storage |
| Answer lines | O(D) table lookups for D groups | output buffer |
| Output | one write per 64 KiB block | 64 KiB |

The tables are built once, so the exponent cost no longer depends on the number of cases.

| Measure | Big O |
|---|---|
| Time | O(maxChunks · chunkBase + P + T) for T lines |
| Space | O(P + maxChunks · chunkBase) |

Summing binomials or doubling n times is impossible for 30-digit n.

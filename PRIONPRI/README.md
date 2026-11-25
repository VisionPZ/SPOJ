# PRIONPRI — Prime or not Prime! (SPOJ)

<https://www.spoj.com/problems/PRIONPRI/>

## Problem

For each given integer n, print YES when n is prime and NO when it is composite.

The first input value is the number of test cases. Each following value is one integer n with 2 <= n <= 10^9. Print one word per case on its own line.

The statement and judge give these bounds:

| item | bound |
|---|---|
| test cases | given by the first input value |
| each value n | 2 to 10^9 |
| judge limit | 1000 ms, 1536 MB |

The value range keeps modular products inside 64 bits.

Sample input:

```
6
16
127
256
513
2048
5097
```

Sample output:

```
NO
YES
NO
NO
NO
NO
```

## Idea

Check a number against a few small divisors and a few modular keys, like testing a lock with several distinct keys.

The algorithm is the Miller-Rabin primality test with bases 2, 3, 5, and 7. It first rejects multiples of twelve small primes. Each base costs O(log n) modular multiplications. Trial division up to the square root would cost about 31623 divisions for every large case. The four bases settle every value in this range.

A short fixed base list gives fast, reliable answers.

## Why It Works

1. A number below 2 is not prime.
2. A number equal to a small prime is prime; a multiple of one is composite.
3. Write n - 1 as an odd part times a power of two.
4. A prime makes every test base reach 1 or n - 1 during repeated squaring.
5. Four fixed bases cover every value up to 10^9.
6. One failing base proves the number composite.

The main terms are these:

| term | meaning |
|---|---|
| `smallPrimes` | the twelve divisors tried before the base tests |
| `oddPart` | the odd factor left after removing powers of two |
| `trailingZeros` | how many powers of two were removed |
| `testBases` | the four bases used by the test |
| `probe` | the current modular power for one base |

The four bases are enough for the stated input range.

A script-generated trace with visible numbers:

```
16: divisible by 2 => NO
127: oddPart 63, trailingZeros 0
2^63 mod 127 = 1 => YES
```

The trace matches the sample: 16 is composite and 127 is prime.

## Code

**Bulk input and hand scanner.** This block loads stdin and reads the positive integers.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips spaces and line breaks between numbers.
Values are read into 64-bit integers before the cast to unsigned.
The buffer flushes after about 128 KiB of text.
Each token costs one pass over its digits.

**Modular power.** This block squares the base and halves the exponent.

```nim
proc powerMod(baseValue, exponentValue, modulusValue: uint64): uint64 =
  var resultValue: uint64 = 1
  var baseReduced = baseValue mod modulusValue
  var exponentLeft = exponentValue
  while exponentLeft > 0'u64:
    if (exponentLeft and 1'u64) != 0'u64:
      resultValue = (resultValue * baseReduced) mod modulusValue
    baseReduced = (baseReduced * baseReduced) mod modulusValue
    exponentLeft = exponentLeft shr 1
  return resultValue
```

Unsigned multiplication wraps the same way as the reference implementation.
Reducing after every product keeps all intermediates below the modulus.
The loop runs once per bit of the exponent.
The cost is logarithmic in the tested number.

**Primality test.** This block applies small divisors, then the four bases.

```nim
proc isPrime(number: uint64): bool =
  if number < 2'u64:
    return false
  const smallPrimes = [2'u64, 3'u64, 5'u64, 7'u64, 11'u64, 13'u64,
                       17'u64, 19'u64, 23'u64, 29'u64, 31'u64, 37'u64]
  for primeValue in smallPrimes:
    if number mod primeValue == 0'u64:
      return number == primeValue
  var oddPart = number - 1'u64
  var trailingZeros = 0
  while (oddPart and 1'u64) == 0'u64:
    oddPart = oddPart shr 1
    trailingZeros += 1
  const testBases = [2'u64, 3'u64, 5'u64, 7'u64]
  for baseValue in testBases:
    var probe = powerMod(baseValue, oddPart, number)
    if probe == 1'u64 or probe == number - 1'u64:
      continue
    var passed = false
    for roundIndex in 1 .. trailingZeros - 1:
      probe = (probe * probe) mod number
      if probe == number - 1'u64:
        passed = true
        break
    if not passed:
      return false
  return true
```

Small divisors handle most composite values before any power is computed.
The trailing-zero loop strips factors of two with shifts.
A base that never reaches n - 1 rejects the number.
The work is logarithmic per base.

**Driver.** This block reads the case count and prints each verdict.

```nim
let caseCount = int(nextInt(inputData, scanPos))
for caseIndex in 0 .. caseCount - 1:
  let candidate = uint64(nextInt(inputData, scanPos))
  if isPrime(candidate):
    appendOutput("YES\n")
  else:
    appendOutput("NO\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop consumes exactly one number per case.
Each verdict adds four bytes to the output buffer.
One final write flushes the remaining text.

## Complexity

The cost splits into input, the primality test, and output.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin bytes | one input string |
| primality test | O(log n) per base, four bases | a few integers |
| output | one line per case | block buffer |

The primality test dominates because input and output stay linear.

The asymptotic costs are these:

| measure | Big O |
|---|---|
| time | O(T log n) for T cases |
| space | O(input bytes) |

Trial division would cost O(sqrt n) per case.
The modular test uses only a handful of multiplications per bit.

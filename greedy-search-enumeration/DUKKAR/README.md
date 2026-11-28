# DUKKAR — Dukkar and Pikka (SPOJ)

<https://www.spoj.com/problems/DUKKAR/>

## Problem

Count entries in row N of Pascal's triangle that are divisible by a prime P. Row N holds N plus 1 entries, starting with row zero. Print one count per test.

Input starts with the test count t. Each following line holds N from 0 to 1000000000000000000 and a prime P from 2 to 100000. Output one integer per test.

| item | bound |
|---|---|
| test count t | below 100000 |
| row index N | 0 to 1000000000000000000 |
| prime P | 2 to 100000 |
| judge limit | 100 ms, 1536 MB |

The huge row index makes building any triangle row impossible.

Sample input:

```
2
2 2
7 7
```

Sample output:

```
1
6
```

## Idea

Lucas' theorem turns a giant row into a small product of base-P digits, like reading a number's digits instead of weighing the whole number. The real algorithm counts entries that survive modulo P, then subtracts that count from the row length. Each test costs at most 60 digit steps. Testing every entry would cost O(N) time.

Two counts from digits replace the entire row.

## Why It Works

1. Lucas' theorem says C(N, K) modulo P is nonzero only when every base-P digit of K is at most the matching digit of N.
2. At one digit, a digit of N equal to d allows d plus 1 choices for the digit of K.
3. Digits choose independently, so the nonzero count is the product of d plus 1 over all digits of N.
4. Every entry is either divisible or not divisible by P, so the answer is N plus 1 minus that product.
5. The product never exceeds N plus 1, so it fits in int64.

| term | meaning |
|---|---|
| `rowNumber` | the row index N |
| `primeBase` | the prime P used as a number base |
| `remaining` | the unfinished part of N during digit extraction |
| `digit` | the current base-P digit of N |
| `notDivisible` | product of digit plus 1 over extracted digits |

For the sample N = 7 and P = 7, base 7 digits are 1 and 0. Their product is 2 times 1, which is 2. The row length is 8, so 8 minus 2 gives 6.

A row index of zero yields one digit product of 1 and an answer of zero.

## Code

**Input and buffer.** The reader loads all tests and parses two integers each.

```nim
const flushBlockBytes = 1 shl 17

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips spaces and line breaks.
The buffer flushes once many answer lines accumulate.
One read pass handles all tests.

**Digit product.** Each test extracts base-P digits and prints the difference.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rowNumber = int64(nextInt(inputData, scanPos))
  let primeBase = int64(nextInt(inputData, scanPos))
  var remaining = rowNumber
  var notDivisible: int64 = 1
  while remaining > 0:
    let digit = remaining mod primeBase
    notDivisible = notDivisible * (digit + 1)
    remaining = remaining div primeBase
  appendOutput($(rowNumber + 1 - notDivisible))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop ends after at most 60 divisions for base 2.
Every digit contributes one multiplication, which stays in int64.
The final subtraction yields the count of divisible entries.

## Complexity

Digit extraction is the only work per test.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| digit product | one division per base-P digit | constant |
| output | one flush per block | block buffer |

Larger primes shorten the digit loop further.

| measure | Big O |
|---|---|
| time | O(t log N), at most 60 divisions per test |
| space | O(1) beyond input and output buffers |

Generating a whole row would cost O(N) per test.

The digit product keeps all 100000 tests well inside the time limit.

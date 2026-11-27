# VZLA2019I — Italian Dinner (SPOJ)

<https://www.spoj.com/problems/VZLA2019I/>

## Problem

An Italian dinner has five courses (antipasto, primo, secondo, contorno, dolce) plus a drink course. Exactly one option is chosen from each of the six courses. Given the number of options for each course on one line, print how many different dinners can be ordered.

| item | bound |
|---|---|
| options per course `Ci` | 1 to 50 |
| judge limit | 1000 ms, 1536 MB |

Sample input:

```
1 1 1 2 1 1
```

Sample output:

```
2
```

More examples from the statement: `2 3 1 2 4 1` gives `48`, and `5 10 2 8 7 4` gives `22400`.

## Idea

A dinner picks one item from each of six dish bowls. Counting them multiplies the six bowl sizes together. The program keeps a running product and prints it.

## Why It Works

1. Two dinners differ if any course differs, and choices in different courses never interfere, so the multiplication principle applies: the total is the product of the six counts.
2. The sample `1 1 1 2 1 1` has exactly two dinners because only the contorno offers two options: `1 * 1 * 1 * 2 * 1 * 1 = 2`.
3. The largest possible product is `50^6 = 15625000000000`, about 1.56 x 10^13, which is far past 2^31 but well inside a 64-bit integer, so the running product is kept as `int64`.
4. The independent oracle multiplies the same six numbers by a different route: it factorizes each count into primes, adds the exponents per prime, and rebuilds the product from the primes. Prime factorization is unique, so both routes must land on the same integer.

| term | meaning |
|---|---|
| `courseCount` | 6, the five courses plus the drink |
| `optionCount` | options offered for one course |
| `dinnerCount` | running product, starts at 1 |

## Code

**Input, scanner and output buffer.** This block loads stdin and prepares the writer.

```nim
const flushBlockBytes = 1 shl 17
const courseCount = 6

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

The whole input is read once into a string. The scanner skips spaces and picks up the next run of digits.

**The product and the print.** This block multiplies the six counts and writes the answer.

```nim
var dinnerCount: int64 = 1
for courseIndex in 0 .. courseCount - 1:
  let optionCount = nextInt(inputData, scanPos)
  dinnerCount = dinnerCount * int64(optionCount)
appendOutput($dinnerCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The cast to `int64` happens before the multiply, so the running product never overflows.

## Complexity

| phase | time | space |
|---|---|---|
| input read | one pass over at most 30 bytes | O(1) |
| product | 6 multiplications | O(1) |
| output | one line | O(1) |

| measure | big O |
|---|---|
| time | O(1) |
| space | O(1) |

Six numbers in, one number out: there is nothing to loop over at scale.

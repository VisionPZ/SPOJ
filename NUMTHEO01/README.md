# NUMTHEO01 — Mad Mod (SPOJ)

<https://www.spoj.com/problems/NUMTHEO01/>

## Problem

Report the remainder of a factorial divided by a given modulus. Each query gives the factorial index and the modulus, and the answer is one integer.

Input starts with the query count `t`. Each query line holds two integers `n` and `x`.

Output holds one line per query with `n! mod x`.

| item | bound |
|---|---|
| queries t | 1 to 15 |
| factorial index n | less than 8388700 |
| modulus x | less than 10^15 |
| judge limit | 4000 ms, 1536 MB |

The modulus is large enough that a naive product times a factor overflows 64 bits.

Sample input:

```
3
5 7
10 231
1 1
```

Sample output:

```
1
21
0
```

## Idea

Keep the running product small by reducing it after each factor, like paying down a balance after every purchase. Split the next factor into two small pieces so both partial products stay inside 64 bits.

The remainder of a product equals the remainder of the reduced factors. Splitting the factor by one thousand keeps each partial product below the signed 64-bit ceiling. A zero remainder lets the loop stop, since later factors keep it zero.

Reduce often, split the multiplier, and stop at zero.

## Why It Works

1. Modular multiplication satisfies `(a*b) mod x = ((a mod x)*(b mod x)) mod x`.
2. The running product always stays below the modulus `x`.
3. A factor below 8388700 splits into a thousands part and a remainder part.
4. The thousands part is at most 8388, so its product with the running value stays below 2^63.
5. Adding the two reduced parts and reducing once gives the exact next remainder.

| term | meaning |
|---|---|
| `factorialLimit` | the index n of the factorial |
| `modulusValue` | the divisor x |
| `productValue` | running remainder of the factorial |
| `highPart` | factor divided by one thousand |
| `lowPart` | factor modulo one thousand |

For `5! mod 7`, the running remainders are `1`, `2`, `6`, `3`, `1`. The last value matches the sample.

A modulus of one returns zero at once.

## Code

**Input and reduced factorial loop.** The reader loads all queries and reduces after every factor.

```nim
const flushBlockBytes = 1 shl 17
const splitStep = 1000

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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let factorialLimit = nextInt(inputData, scanPos)
  let modulusValue = nextInt(inputData, scanPos)
  if modulusValue == 1:
    appendOutput("0\n")
    continue
  var productValue: int64 = 1
  var factorCursor = 1
  while factorCursor <= factorialLimit:
    let highPart = factorCursor div splitStep
    let lowPart = factorCursor mod splitStep
    let lowProduct = (productValue * int64(lowPart)) mod int64(modulusValue)
    let highProduct = (productValue * int64(highPart)) mod int64(modulusValue)
    productValue = (lowProduct + highProduct * int64(splitStep)) mod int64(modulusValue)
    if productValue == 0:
      break
    factorCursor += 1
  appendOutput($productValue & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The split keeps both partial products below 2^63.
A zero remainder ends that query early.
Every answer passes through the block buffer.

## Complexity

Each query walks the factor range up to n or until the remainder becomes zero.

| phase | time | space |
|---|---|---|
| input read | one pass over the tokens | one input string |
| factorial loop | one split multiply per factor | a few integers |
| output | one line per query | block buffer |

The factor count n drives the loop length.

| measure | Big O |
|---|---|
| time | O(t*n) worst case |
| space | O(1) beyond the input string |

Storing the full factorial would need millions of digits and overflow any fixed-width integer.

Reduce after every factor, split the multiplier, and stop at zero.

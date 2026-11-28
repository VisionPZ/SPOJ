# SIS2002BO1 — Cuente con Cantor (SPOJ)
<https://www.spoj.com/problems/SIS2002BO1/>

## Problem

Fractions are listed along diagonals of a grid, and each query asks for the fraction at a given position. The answer prints the position and its numerator and denominator in a fixed Spanish sentence.

Input starts with an integer t from 1 to 20. Each of the next t lines holds one term number from 1 to 10000000. Output prints one line per query in the form TERMINO n ES p/q, where p over q is the matching fraction.

| item | bound |
|---|---|
| query count t | 1 to 20 |
| term number | 1 to 10000000 |
| largest diagonal | 4472 |
| judge limit | 1000 ms, 1536 MB |

The grid row is the numerator and the column is the denominator. Diagonals alternate direction, so odd diagonals run upward and even diagonals run downward.

Sample input:

```
3
3
14
7
```

Sample output:

```
TERMINO 3 ES 2/1
TERMINO 14 ES 2/4
TERMINO 7 ES 1/4
```

## Idea

Walk down the diagonal strips of a tiled floor, counting tiles until reaching the requested one, like counting seats row by row in a stadium. The algorithm grows triangular sums until one covers the term number. Each query costs about 4472 additions, and 20 queries stay tiny. Building the whole fraction table up to ten million would waste time and memory. Takeaway: find the diagonal by accumulating triangular sums, then read off the fraction.

## Why It Works

1. Diagonal k holds k fractions whose numerator plus denominator is k + 1.
2. The first k diagonals hold k times (k + 1) divided by 2 fractions.
3. The smallest diagonal reaching the term number gives position within that diagonal.
4. Even diagonals run from numerator 1 upward, so the position is the numerator.
5. Odd diagonals run from numerator k downward, so the position is the denominator.

| term | meaning |
|---|---|
| `diagonal` | current diagonal number k |
| `previousTerms` | fractions before the current diagonal |
| `positionInDiagonal` | one-based place inside the diagonal |
| `numerator` | top of the printed fraction |
| `denominator` | bottom of the printed fraction |

Term 3 lands on diagonal 2 at position 2, giving 2 over 1.
Term 14 lands on diagonal 5 at position 4, giving 2 over 4.
Term 7 lands on diagonal 4 at position 1, giving 1 over 4. These match the sample output.

## Code

**Input and scanning.** The reader loads all query numbers with a digit scanner.

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
```

`inputData` collects the full input before parsing.
`nextInt` skips newlines and reads one positive term number.

**Diagonal walk and output.** Each query finds its diagonal and prints the fraction.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let termNumber = nextInt(inputData, scanPos)
  var diagonal = 1
  var previousTerms = 0
  while previousTerms + diagonal < termNumber:
    previousTerms += diagonal
    diagonal += 1
  let positionInDiagonal = termNumber - previousTerms
  var numerator = 0
  var denominator = 0
  if (diagonal mod 2) == 0:
    numerator = positionInDiagonal
    denominator = diagonal + 1 - positionInDiagonal
  else:
    numerator = diagonal + 1 - positionInDiagonal
    denominator = positionInDiagonal
  appendOutput("TERMINO " & $termNumber & " ES " & $numerator & "/" & $denominator)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`previousTerms + diagonal` is the triangular sum for the current diagonal.
`diagonal mod 2` selects the direction of enumeration.
`appendOutput` buffers every answer line and flushes once.

## Complexity

Each query walks at most 4472 diagonals.

| phase | time | space |
|---|---|---|
| input read | one pass over t numbers | one input string |
| diagonal walk | up to 4472 increments per query | a few integers |
| output | t lines | block buffer |

| measure | Big O |
|---|---|
| time | O(t times square root of the term number) |
| space | O(1) |

Precomputing ten million fractions would use linear space instead of constant space. Takeaway: triangular sums locate any term without storing the grid.

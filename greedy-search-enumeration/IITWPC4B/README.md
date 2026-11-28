# IITWPC4B — Maggu and Triangles (SPOJ)

<https://www.spoj.com/problems/IITWPC4B/>

## Problem

Count the integer-sided triangles whose perimeter equals a given length, counting each set of side lengths once.

Input starts with T, then T lines each holding one perimeter n. Output one count per line.

| item | bound |
|---|---|
| test cases T | 1 to 1e5 |
| perimeter n | 1 to 1e9 |
| judge limit | 2000 ms, 1536 MB |

The large T and large n rule out enumerating sides for each case.

Sample input:

```
3
5
7
9
```

Sample output:

```
1
2
3
```

Perimeter nine allows sides 3 3 3, 2 3 4, and 1 4 4.

## Idea

Picture two cuts in a rope where the longest piece stays shorter than the other two together.

Sort sides as a at most b at most c. The triangle condition becomes a plus b greater than c, with a plus b plus c equal to n. Alcuin's sequence gives a closed form: round n squared over 48 for even n, and round n plus three squared over 48 for odd n. The program evaluates that form once per case. Enumerating candidate side pairs for each of 1e5 cases cannot finish in time.

## Why It Works

1. Ordering sides removes congruent copies, so a at most b at most c is enough.
2. The longest side is under half the perimeter, so it is shorter than the other two combined.
3. Counting ordered side triples with that bound yields Alcuin's sequence.
4. Even perimeters give round n squared over 48; odd ones give round n plus three squared over 48.
5. Adding half the denominator performs round-to-nearest with integer division.

| term | meaning |
|---|---|
| `perimeter` | the total wire length n |
| `squaredValue` | n squared, or n plus three squared for odd n |
| `roundingOffset` | twenty-four, half of the denominator |
| `triangleCount` | the number of distinct triangles |

Small cases are checked by enumerating all side triples before trusting the form.

A script traces perimeter nine:

```
c = 3: a ranges 3..3 -> 1
c = 4: a ranges 1..2 -> 2
total = 3
formula (9+3)^2 = 144, (144+24)/48 = 3
```

The enumeration and the closed form agree on the sample answer.

## Code

**Input and scanner.** The reader loads stdin once and parses integers by hand.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const roundingOffset = 24
const scaleFactor = 48

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The scanner skips the line breaks between test cases.
The denominator and its half are named constants.

**Buffered output.** One string collects every answer line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Blocks are written only after many lines accumulate.
The final write flushes the tail.

**Closed-form evaluation.** Each perimeter is squared, rounded, and written.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let perimeter = int64(nextInt(inputData, scanPos))
  var squaredValue: int64
  if (perimeter mod 2) == 0:
    squaredValue = perimeter * perimeter
  else:
    let shiftedPerimeter = perimeter + 3
    squaredValue = shiftedPerimeter * shiftedPerimeter
  let triangleCount = (squaredValue + int64(roundingOffset)) div int64(scaleFactor)
  appendOutput($triangleCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Only even squares are divided, so exact halfway ties never occur.
Squares up to 1e18 stay inside signed 64-bit range.
One integer division replaces all side enumeration.

## Complexity

The loop does constant work per test case after input is read.

| phase | time | space |
|---|---|---|
| input read | one pass over T perimeters | one input string |
| formula | one square and one division per case | constant |
| output | one line per case | block buffer |

Memory does not grow with the number of cases.

| measure | Big O |
|---|---|
| time | O(T) |
| space | O(1) besides input |

Enumerating sides costs O(n) per case and cannot handle large perimeters.
The closed form is the takeaway.

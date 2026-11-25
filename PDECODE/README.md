# PDECODE — Decode the Strings (SPOJ)

<https://www.spoj.com/problems/PDECODE/>

## Problem

Undo repeated permutation shuffles of a short string using the shuffle count and the shuffling map. The shuffle count can reach one billion, so replaying it step by step is too slow.

Each case starts with n and m on one line, then n permutation numbers, then the encoded string. The permutation sends each old position pi to a new position i. Repeating that step m times produced the given string.

Print the original string, preserving spaces. A line with two zeros ends input.

| item | bound |
|---|---|
| string length n | 1 to 80 |
| shuffle count m | 1 to 1000000000 |
| cases | until the 0 0 line |
| judge limit | 1000 ms, 1536 MB |

The huge shuffle count forces a power-of-a-permutation method.

Sample input:

```
5 3
2 3 1 5 4
helol
16 804289384
13 10 2 7 8 1 16 12 15 6 5 14 3 4 11 9
scssoet tcaede n
8 12
5 3 4 2 1 8 6 7
encoded?
0 0
```

Sample output:

```
hello
second test case
encoded?
```

## Idea

Undoing a shuffle is like walking backward around a carousel: after a whole cycle, every seat returns home. Compute the shuffled map after m applications, then place each encoded character at its original seat.

The method is binary exponentiation of a permutation, followed by inverse placement. Each case costs O(n log m) time.

Replaying m steps costs O(nm), which explodes at one billion. Squaring the map collapses those steps into about thirty compositions.

## Why It Works

1. One shuffle step puts the character of position pi into position i.
2. Composing the map with itself k times gives the map after k shuffles.
3. Binary representation of m needs only about 30 bits.
4. Squaring the map doubles the jump, so the bits of m build the final map.
5. The final map sends each old position to its encoded position.
6. Placing encoded character i at that map position restores the original string.

The key values:

| term | meaning |
|---|---|
| `forwardPerm` | one shuffle step, stored with zero-based positions |
| `powerPerm` | the composed map after m steps |
| `basePerm` | the current squared map |
| `encodedText` | the string read from the case |

Every position is moved exactly once by the composition.

A trace of the first sample case, with n = 5 and m = 3:

```
permutation      2 3 1 5 4
cycles           (1 2 3) and (4 5)
m mod 3 = 0       first cycle stays put
m mod 2 = 1       second cycle swaps
final map        1 2 3 5 4
encoded chars    h e l o l
decoded chars    h e l l o
```

The trace gives the sample word hello.

Spaces inside a string are kept, because the whole input line is read as text.

## Code

**Input and output plumbing.** All lines are read once, and numbers are scanned by hand.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
var inputLines = newSeq[string]()
while readLine(stdin, inputLine):
  inputLines.add inputLine
  inputData.add inputLine
  inputData.add '\n'

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

A line holds the encoded string with spaces. The scanner reads numeric lines. The buffer flushes in blocks.

**Permutation composition.** Composing maps builds powers of the shuffle.

```nim
proc composePermutations(leftPerm: seq[int], rightPerm: seq[int]): seq[int] =
  let count = leftPerm.len
  var composed = newSeq[int](count)
  for index in 0 .. count - 1:
    composed[index] = leftPerm[rightPerm[index]]
  return composed
```

Each output entry picks one mapped position. The cost is linear in n. Composition is associative.

**Decode and write.** Squaring handles huge m, then characters move home.

```nim
var linePos = 0
while linePos < inputLines.len:
  var headerPos = 0
  let stringLength = nextInt(inputLines[linePos], headerPos)
  let repeatCount = nextInt(inputLines[linePos], headerPos)
  linePos += 1
  if stringLength == 0 and repeatCount == 0:
    break
  var permPos = 0
  var forwardPerm = newSeq[int](stringLength)
  for index in 0 .. stringLength - 1:
    forwardPerm[index] = nextInt(inputLines[linePos], permPos) - 1
  linePos += 1
  let encodedText = inputLines[linePos]
  linePos += 1
  var powerPerm = newSeq[int](stringLength)
  for index in 0 .. stringLength - 1:
    powerPerm[index] = index
  var basePerm = forwardPerm
  var remaining = repeatCount
  while remaining > 0:
    if (remaining and 1) == 1:
      powerPerm = composePermutations(powerPerm, basePerm)
    basePerm = composePermutations(basePerm, basePerm)
    remaining = remaining shr 1
  var decodedText = newSeq[char](stringLength)
  for index in 0 .. stringLength - 1:
    decodedText[powerPerm[index]] = encodedText[index]
  for index in 0 .. stringLength - 1:
    appendOutput($decodedText[index])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The zero pair ends parsing. Each set bit composes one squared map. Every decoded line ends with one newline.

## Complexity

Each case composes maps for the bits of m.

| phase | time | space |
|---|---|---|
| input read | one pass over input lines | input string and lines |
| exponentiation | about 30 compositions of n entries | two map arrays |
| inverse placement | n character moves | decoded array |
| output | one line per case | block buffer |

The number of compositions follows the bit length of m.

| measure | Big O |
|---|---|
| time | O(n log m) per case |
| space | O(n) |

Replaying m shuffles would cost O(nm), which is impossible for one billion steps. Binary exponentiation keeps the work tiny.

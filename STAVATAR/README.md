# STAVATAR — The Last String Bender (SPOJ)

<https://www.spoj.com/problems/STAVATAR/>

## Problem

Two strings start equal in length. Each operation swaps the characters of both strings inside one inclusive range. Recover the two strings after every operation has been applied in order.

The input gives `stringLength` on one line, then the two passwords on their own lines, then `operationCount`, then one pair `L R` per operation. Print the two final strings on two lines. Positions start at zero, and `R` is included in the swap.

| item | bound |
|---|---|
| `stringLength` | 1 to 1000000 |
| `operationCount` | 1 to 1000000 |
| swap range | 0 ≤ L ≤ R < stringLength |
| judge limit | 500 ms, 1536 MB |

Each password may contain spaces and other printable characters, so both password lines are read whole.

Sample input:

```
6
abcdef
ghijkl
4
2 4
1 3
4 4
4 5
```

Sample output:

```
ahcdkl
gbijef
```

## Idea

Swapping a range twice changes nothing, like flipping a light switch twice. Record only how many swaps cover each position, modulo two. The algorithm is a difference array of parity bits: mark each range endpoint, then sweep once with a running `xor`. A naive pass over every position of every range costs O(N·M), while the sweep costs O(N+M). Take the parity once, then decide each output character in constant time.

## Why It Works

1. A character at one position changes side exactly when an odd number of ranges cover that position.
2. Adding a flip at `L` and a flip at `R + 1` makes every later sweep step flip precisely inside `[L, R]`.
3. The running `parityState` is the `xor` of all flips seen up to the current position.
4. If `parityState` is one, the two original characters exchange places; otherwise they stay.
5. The sweep visits each position once, so the order of operations never needs to be replayed.

| term | meaning |
|---|---|
| `swapParity` | flip marker at each range endpoint |
| `parityState` | number of covering ranges modulo two |
| `firstPassword` | original characters of the first password |
| `secondPassword` | original characters of the second password |
| `firstResult` | reconstructed first password |

A worked trace for positions zero to five of the sample follows.

```
operation     flips at endpoints
2 4           swapParity[2]=1, swapParity[5]=1
1 3           swapParity[1]=1, swapParity[4]=1
4 4           swapParity[4]=0, swapParity[5]=0
4 5           swapParity[4]=1, swapParity[6]=1
position      0  1  2  3  4  5
parityState   0  1  0  0  1  0
firstResult   a  h  c  d  k  l
secondResult  g  b  i  j  e  f
```

The parity row matches `ahcdkl` and `gbijef`, the sample answer.

## Code

**Input and hand scanner.** The reader keeps all stdin in one string and parses integers by skipping separators.

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

The two password lines are copied whole, so spaces survive.
`scanPos` moves past the newline after each line.
Token parsing does not depend on line breaks.

**Buffered output.** Text accumulates and flushes only in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One buffer serves both output lines.
A block is written only after it reaches `flushBlockBytes`.
The final flush happens after the result strings are built.

**Password extraction and endpoint marks.** Each operation writes only two flip markers.

```nim
let stringLength = nextInt(inputData, scanPos)
while scanPos < inputData.len and inputData[scanPos] != '\n':
  scanPos += 1
scanPos += 1

var firstPassword = ""
var secondPassword = ""
for charIndex in 0 .. stringLength - 1:
  firstPassword.add inputData[scanPos + charIndex]
scanPos += stringLength + 1
for charIndex in 0 .. stringLength - 1:
  secondPassword.add inputData[scanPos + charIndex]
scanPos += stringLength + 1

let operationCount = nextInt(inputData, scanPos)
var swapParity = newSeq[int](stringLength + 1)
for operationIndex in 0 .. operationCount - 1:
  let leftPosition = nextInt(inputData, scanPos)
  let rightPosition = nextInt(inputData, scanPos)
  swapParity[leftPosition] = swapParity[leftPosition] xor 1
  swapParity[rightPosition + 1] = swapParity[rightPosition + 1] xor 1
```

The extra cell at index `stringLength` holds the final endpoint flip.
Both endpoints use `xor`, so repeated ranges cancel.
Each operation costs two array writes.

**Parity sweep and output.** One pass builds both reconstructed strings.

```nim
var parityState = 0
var firstResult = ""
var secondResult = ""
for charIndex in 0 .. stringLength - 1:
  parityState = parityState xor swapParity[charIndex]
  if parityState == 1:
    firstResult.add secondPassword[charIndex]
    secondResult.add firstPassword[charIndex]
  else:
    firstResult.add firstPassword[charIndex]
    secondResult.add secondPassword[charIndex]

appendOutput(firstResult)
outputBuffer.add '\n'
appendOutput(secondResult)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The sweep reads each marker once and touches each character once.
A single `xor` decides whether the two characters trade places.
Both result strings are appended before the last flush.

## Complexity

The sweep and the output dominate the runtime.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin bytes | one input string |
| endpoint marks | two writes per operation | array of length plus one |
| parity sweep | one step per position | two result strings |
| output | one write per block | block buffer |

| measure | Big O |
|---|---|
| time | O(N + M) |
| space | O(N) |

Replaying every swap over its whole range costs O(N·M), while the parity sweep settles each position once. The difference array turns a slow simulation into a single left-to-right pass.

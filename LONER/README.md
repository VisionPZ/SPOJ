## Problem

A board is a line of squares, each empty or holding a pawn. A jump lifts a pawn over an adjacent pawn into the next square and removes the jumped pawn. Jumps go left or right. Print yes when a sequence of jumps can leave exactly one pawn, and print no otherwise.

| Quantity | Bound |
| --- | --- |
| Test cases | first integer, no stated bound |
| Board length | 1 to 32000 |
| Board symbols | 0 and 1, no spaces |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

Board length sets the scan work, and case count sets the output size.

## Idea

We read the board as a word and scan it with an 18-state automaton. The automaton comes from a regular expression that accepts exactly the boards reducible to one pawn. It replaces a search over move orders with one transition per square.

Cost per square: one character test and one table lookup.

## Why It Works

Playing the game backwards from one pawn generates every winning board. Moore and Eppstein proved that those boards form a regular language. Their expression has four parts:

- 1, 011, 110: short boards that win after at most two jumps.
- 11(01)*[00 + 00(11)+ + (11)+00 + (11)*1011 + 1101(11)*](10)*11: a chain holding one pair of empty squares.
- 11(01)*(11)*01 and 10(11)*(10)*11: chains that finish at the far edge.
- 0* at both ends: empty squares outside the pawn region.

A star means zero or more repeats, and a plus means one or more repeats. The bracket offers five ways to shape the middle of the chain.

We compile that expression into 18 states. Each state records which part of a winning chain the scanned prefix can still complete. State 0 starts every scan, and five states accept.

The script in gen.py prints one winning path for the first sample board.

| Step | Board |
| --- | --- |
| 0 | 0110011 |
| 1 | 0001011 |
| 2 | 0001100 |
| 3 | 0010000 |

Each row follows from the previous one by one jump, and the last row holds a single pawn.

## Code

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const dfaOnZero = [1, 1, 4, 4, 7, 3, 3, 7, 11, 12, 10, 10, 10, 8, 11, 10, 12, 14]
const dfaOnOne = [2, 3, 5, 6, 8, 9, 9, 10, 4, 13, 10, 14, 15, 16, 7, 11, 17, 16]
const dfaAccepting = [0, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
```

The three tables hold the whole automaton. Each index is a state, and each entry names the next state. The scan touches one entry per board square.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
```

The read loop ends at end of input. One buffer holds every line, so parsing never waits on the stream. The cost is one pass over the input.

```nim
proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value
```

The scanner skips separators before each integer. Digit values come from character arithmetic, so no conversion object is built. The loop stops at the first non-digit.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes only after reaching the block size. Reusing it avoids a fresh allocation at every flush. Writes stay large and rare.

```nim
let caseCount = nextInt(inputData, scanPos)
for i in 0..<caseCount:
  let boardLength = nextInt(inputData, scanPos)
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '1'):
    scanPos += 1
  var automatonState = 0
  for j in 0..<boardLength:
    if inputData[scanPos] == '1':
      automatonState = dfaOnOne[automatonState]
    else:
      automatonState = dfaOnZero[automatonState]
    scanPos += 1
  if dfaAccepting[automatonState] == 1:
    appendOutput("yes\n")
  else:
    appendOutput("no\n")
```

The outer loop runs once per case, and the inner loop runs exactly boardLength times. The skip loop leaves the cursor on the first board symbol. Reading the board as digits would lose leading zeros, so the code tests symbols directly.

```nim
stdout.write outputBuffer
outputBuffer.setLen 0
```

The final write emits any bytes left in the buffer. The empty buffer is reused rather than replaced. This flushes the last answer once.

## Complexity

Reading stores all input bytes once, so that phase uses O(input) time and space. Scanning costs O(n) time per board and O(1) extra space. Output costs O(output) time and stays within one block of memory.

Total time is O(input + output), and total space is O(input). A search over all jump orders grows exponentially with the pawn count.

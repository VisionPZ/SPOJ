# SMILEY1807 — 1807 (SPOJ)
<https://www.spoj.com/problems/SMILEY1807/>

## Problem

Start with one string of the digits 1, 8, 0 and 7. Take the longest subsequence with four blocks. The blocks hold ones, then eights, then zeros, then sevens. Print that length, or zero when a block is missing.

Input holds one test case: one string of up to one million digits. Output holds one line with the length.

| quantity | bound |
|---|---|
| string length | up to 1000000 |
| allowed digits | 1, 8, 0, 7 only |
| test cases | one |
| judge limit | 1000 ms, 1536 MB |

A single left-to-right pass handles the largest string.

Sample input:

```
1800777700088888000777
```

Sample output:

```
13
```

The winning subsequence is 1800000000777, made of one 1, one 8, eight 0s, and three 7s.

## Idea

Keeping four running lengths is like filling four cups in a row: you open the next cup only after the previous one holds a drop.

Each new digit extends the current block or opens the next block. The four lengths store the longest prefix of the pattern seen so far, so the last length is the answer. This is four-state dynamic programming with one update per digit.

Trying every choice of four cut positions would cost O(L^4) for a string of length L. Four stored lengths replace that search with O(L).

Let each state keep a cumulative length, then read the answer from the final state.

## Why It Works

1. A valid subsequence is a block of each digit in the order 1, 8, 0, 7.
2. The first state counts the longest block of ones seen so far.
3. An eight extends that block and starts the eights block when possible.
4. Each later digit extends its own state from the best previous state.
5. Expanding a state may reuse a longer earlier block seen at this digit.
6. The final state counts a complete subsequence, so it is the answer.

| term | meaning |
|---|---|
| `onesLength` | length of the longest leading ones block |
| `onesEightsLength` | length of the best ones then eights prefix |
| `onesEightsZerosLength` | length of the best prefix ending in zeros |
| `fullLength` | length of the best complete subsequence |

Each state stores a total length, not the size of its last block.

In the sample, the first 1 and 8 set the first two states to 1 and 2. The early zeros raise the third state to 4, and four early sevens raise the last state to 8. Later zeros raise the third state to 10, and the final three sevens raise the last state from 8 to 11, then 12, then 13.

An eight is ignored until a one exists, and a zero is ignored until an eight exists. The explicit check at the end returns zero if any block never appeared. All counts fit in an integer because the string length is at most one million.

## Code

**Input and buffer.** The reader loads the full string and sets up the output path.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The whole input arrives in one string.
`appendOutput` writes bytes in large blocks.
One final flush emits the single answer line.

**Four states.** Each digit updates one state with a current best value.

```nim
var onesLength = 0
var onesEightsLength = 0
var onesEightsZerosLength = 0
var fullLength = 0

for charIndex in 0 .. inputData.len - 1:
  let currentChar = inputData[charIndex]
  if currentChar == '1':
    onesLength = onesLength + 1
  elif currentChar == '8' and onesLength > 0:
    if onesEightsLength < onesLength:
      onesEightsLength = onesLength
    onesEightsLength = onesEightsLength + 1
  elif currentChar == '0' and onesEightsLength > 0:
    if onesEightsZerosLength < onesEightsLength:
      onesEightsZerosLength = onesEightsLength
    onesEightsZerosLength = onesEightsZerosLength + 1
  elif currentChar == '7' and onesEightsZerosLength > 0:
    if fullLength < onesEightsZerosLength:
      fullLength = onesEightsZerosLength
    fullLength = fullLength + 1

var answer = fullLength
if onesLength == 0 or onesEightsLength == 0 or onesEightsZerosLength == 0:
  answer = 0
appendOutput($answer)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each comparison takes the larger previous prefix.
A block grows by one digit at a time.
The guard removes answers with a missing block.

## Complexity

The scan touches each character once.

| phase | time | space |
|---|---|---|
| input read | one pass over the string | one input string |
| state updates | one comparison per digit | four integers |
| output | one line | block buffer |

String length sets the total running time.

| measure | Big O |
|---|---|
| time | O(L) |
| extra space | O(1) |

Trying all cut positions would take O(L^4) time.

The four states give the longest valid subsequence in one pass.

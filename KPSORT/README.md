# KPSORT — Weird sorting (SPOJ)

<https://www.spoj.com/problems/KPSORT/>

## Problem

Decide whether a sequence can become non-decreasing by repeatedly reversing everything to the left and right of one chosen element. Print one digit per test case and no separators.

Each case starts with N, followed by N integers whose absolute value stays at most 1000. A case with N = 0 ends the input. Print 1 when the sorted arrangement is reachable and 0 otherwise, with no spaces or line breaks.

| item | bound |
|---|---|
| sequence length N | 1 to 100 |
| element value | -1000 to 1000 |
| test cases | at most 100 |
| judge limit | 1000 ms, 1536 MB |

The value of N decides which permutations the moves can reach.

Sample input:

```
5
7 1 3 9 8
2
2 1
0
```

Sample output:

```
10
```

## Idea

Think of the sequence as beads on a string: one chosen bead stays put while both loose ends flip, like turning two halves of a necklace around a clasp. The flips generate a whole permutation group, and sorting depends only on the parity of the permutation needed. For most lengths every permutation is reachable, so the answer is always 1. When N is at least six and equals two modulo four, the moves reach only even permutations, so an odd inversion count blocks sorting.

A brute-force search over arrangements grows factorially and stalls at N = 6. Counting inversions takes one pass over pairs and settles the case at once.

## Why It Works

1. A move with pivot p reverses p elements on the left and n - 1 - p on the right.
2. Its parity is the sum of the two reversal parities. That sum changes with p when n is odd, and stays fixed when n is even.
3. For odd n, or n divisible by four, both parities occur, so all permutations are reachable.
4. For n at least six and n equal to two modulo four, every move is even and only even permutations are reachable.
5. Equal values let us assign sorted positions in either parity, so duplicates remove the parity block.
6. With n = 2 both reversals are empty, so only an already sorted pair works.

| term | meaning |
|---|---|
| `sequenceLength` | number of values in the current case |
| `hasEqualValues` | true when some value appears twice |
| `inversionParity` | parity of the count of out-of-order pairs |
| `appendOutput` | buffered write of one answer digit |

The parity of the sorting permutation and the parity of the inversion count are the same.

A script traced four small cases with breadth-first search and compared them with the parity rule.

```
[2, 1, 3, 4, 5, 6] n = 6 inversions = 1 parity = 1 BFS reachable = False
[1, 2, 3, 4, 5, 6] n = 6 inversions = 0 parity = 0 BFS reachable = True
[1, 1, 3, 4, 5, 6] n = 6 inversions = 0 parity = 0 BFS reachable = True
[7, 1, 3, 9, 8] n = 5 inversions = 3 parity = 1 BFS reachable = True
```

The second line is the sorted case, the first line is its odd neighbor, and the last line shows why odd lengths never block sorting.

The scanner also reads minus signs because input values may be negative. The N = 2 branch runs before any parity test.

## Code

**Hand reader and sign-aware scanner.** The input is loaded once, then integers are parsed one token at a time.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value
```

The `while readLine` loop sees every line, including the final empty one.
The scanner skips separators and accepts a leading minus sign.
One call advances `scanPos` past exactly one integer.

**Buffered answer path and case decision.** Each case checks the length first, then duplicates, then inversion parity.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let sequenceLength = nextInt(inputData, scanPos)
  if sequenceLength == 0:
    break
  var sequenceValues = newSeq[int](sequenceLength)
  for valueIndex in 0 .. sequenceLength - 1:
    sequenceValues[valueIndex] = nextInt(inputData, scanPos)
  if sequenceLength == 1:
    appendOutput("1")
  elif sequenceLength == 2:
    if sequenceValues[0] <= sequenceValues[1]:
      appendOutput("1")
    else:
      appendOutput("0")
  elif sequenceLength mod 2 == 1 or sequenceLength mod 4 == 0:
    appendOutput("1")
  else:
    var hasEqualValues = false
    for leftIndex in 0 .. sequenceLength - 1:
      for rightIndex in leftIndex + 1 .. sequenceLength - 1:
        if sequenceValues[leftIndex] == sequenceValues[rightIndex]:
          hasEqualValues = true
    if hasEqualValues:
      appendOutput("1")
    else:
      var inversionParity = 0
      for leftIndex in 0 .. sequenceLength - 1:
        for rightIndex in leftIndex + 1 .. sequenceLength - 1:
          if sequenceValues[leftIndex] > sequenceValues[rightIndex]:
            inversionParity = 1 - inversionParity
      if inversionParity == 0:
        appendOutput("1")
      else:
        appendOutput("0")

outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop stops at N = 0 and writes no digit for the sentinel.
The duplicate scan runs only in the alternating-group case.
A single newline follows all digits, matching the required output bytes.

## Complexity

Each case parses its values, then scans pairs only when the length forces a parity check.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| case decision | up to N squared pair checks | N stored integers |
| output | one buffered write | block buffer |

The pair scan is small because N never exceeds 100.

| measure | Big O |
|---|---|
| time per case | O(N^2) worst case |
| space per case | O(N) |

Searching all reachable arrangements would cost factorial time, while the parity test stays quadratic. The parity rule settles every case with a short deterministic scan.

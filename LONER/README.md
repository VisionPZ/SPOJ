# LONER — The Loner (SPOJ)
<https://www.spoj.com/problems/LONER/>

## Problem

A pawn jumps over a neighbor into an empty cell and removes that neighbor. A one-dimensional board asks whether one pawn can survive.

The input starts with the test count. Each case gives a board length and a string of `0` and `1` characters. A `1` marks a pawn. Print `yes` when the board can be won, and `no` otherwise.

The judge bounds are:

| Item | Bound |
| --- | --- |
| Board length | at most 32000 |
| Board symbols | `0` and `1`, no spaces |
| Judge time | 1000 ms |
| Memory | 1536 MB |
| Source size | 50000 B |

Every board is read as one short string.

Sample input and output:

Input:

```
2
7
0110011
6
111001
```

Output:

```
yes
no
```

## Idea

A jump only rewrites a small pattern of neighbor cells. Think of crossing names off a checklist: the remaining groups decide the result, not the order.

The program compiles the board into a deterministic finite automaton (a fixed machine with 18 states). Each cell moves the state through one of two tables. Five states accept. Each cell costs one table lookup. A search over all jump orders would explore exponentially many boards.

Takeaway: one scan replaces every possible sequence of jumps.

## Why It Works

The automaton captures all reachable pawn patterns with a fixed memory.

1. A jump replaces a pair of neighbors plus an empty cell by one pawn.
2. That rewrite changes only local groups, so finite memory suffices.
3. `automatonState` records the group pattern of the scanned prefix.
4. `dfaOnZero` and `dfaOnOne` give the next state for each symbol.
5. The scan reports `yes` when `dfaAccepting` marks the final state.

The tables are:

| Table | Role |
| --- | --- |
| `dfaOnZero` | Next state after an empty cell |
| `dfaOnOne` | Next state after a pawn |
| `dfaAccepting` | Winning final states |

Three tables drive the whole game.

A script traced the sample boards:

| Board | States visited | Final state | Answer |
| --- | --- | --- | --- |
| `0110011` | 0 → 1 → 3 → 6 → 3 → 4 → 8 → 4 | 4 | yes |
| `111001` | 0 → 2 → 5 → 9 → 12 → 10 → 10 | 10 | no |

The accepting table gives `yes` only for the first board.

## Code

**Automaton tables.**

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const dfaOnZero = [1, 1, 4, 4, 7, 3, 3, 7, 11, 12, 10, 10, 10, 8, 11, 10, 12, 14]
const dfaOnOne = [2, 3, 5, 6, 8, 9, 9, 10, 4, 13, 10, 14, 15, 16, 7, 11, 17, 16]
const dfaAccepting = [0, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
```

Three constant arrays describe the machine. Index 0 is the start state. States 2, 3, 4, 6, and 7 accept.

**Input and scanner.**

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value
```

All input lines join one buffer. `nextInt` skips non-digits and builds values digit by digit. The scanner reads board lengths even when digits span lines.

**Output buffer.**

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Answers collect in one string. A flush starts after `flushBlockBytes` bytes. This avoids a write per case.

**Board scan.**

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

stdout.write outputBuffer
outputBuffer.setLen 0
```

The cursor skips separators, then reads exactly `boardLength` symbols. Each symbol applies one table transition. The final state selects `yes` or `no`.

**Final flush.**

```nim
stdout.write outputBuffer
outputBuffer.setLen 0
```

One write emits the remaining answers. The extra `setLen 0` releases the buffer at exit.

## Complexity

Each board costs one pass and constant memory.

| Phase | Time | Space |
| --- | --- | --- |
| Input | O(Total characters) | O(Total characters) |
| Automaton scan | O(B) per board | O(1) |
| Output | O(T) | O(1) |

B is one board length and T is the case count.

| Measure | Bound |
| --- | --- |
| Time | O(Total board length) |
| Space | O(Input size) |

The scan is linear and uses no search.

Enumerating jump orders would branch on every triple of cells.

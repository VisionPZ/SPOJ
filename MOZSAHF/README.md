# MOZSAHF — Sharmeen And Her Friends (SPOJ)

<https://www.spoj.com/problems/MOZSAHF/>

## Problem

Sharmeen joins n visiting friends, so n + 1 people must form two equal teams. Decide whether that split exists and print the matching answer.

The input is one integer n. Print `yes` when the split exists and `no` otherwise, on one line.

The limits from the statement:

| Item | Bound |
|---|---|
| Friends | 1 ≤ n ≤ 100000 |
| Players | n + 1 |
| Output | `yes` or `no` on one line |
| Judge limit | 1000 ms, 1536 MB |

The player total decides the answer, so no team list is needed.

The sample case:

```
5
```

```
yes
```

## Idea

Adding Sharmeen to her friends is like adding yourself to a queue before splitting it into two equal lines. The split exists when n + 1 is even, which happens exactly when n is odd. The program reads one integer and tests parity with `mod`. The test costs one operation after parsing. Building the two teams would cost O(n) work per case. Parity settles the answer without enumerating anyone.

Parity replaces team construction entirely.

## Why It Works

1. The game includes Sharmeen, so the headcount is n + 1 players.
2. Two equal teams require an even headcount.
3. The value n + 1 is even exactly when n is odd.
4. The `mod` operation reports that parity in constant time.

The terms used by the program:

| Term | Meaning |
|---|---|
| `friendCount` | number of friends who visited |
| `scanPos` | index of the next unread input byte |
| `firstDigitValue` | digit value of the character `0` |
| `outputBuffer` | string that collects the answer line |
| `appendOutput` | procedure that appends text and flushes blocks |

Every value names a real quantity from the statement.

A script-traced example from `gen.py`:

```
friends 5
people 6
answer yes
```

Six players split into two teams of three, so the sample prints `yes`.

## Code

**Input buffer and hand scanner.** This block reads all input and defines the index scanner.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

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
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value
```

One readLine loop collects stdin into `inputData`.
The scanner skips separators and builds the number from digits.
Parsing costs one pass over the input bytes.

**Buffered output.** This block stores the answer and flushes large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes once it reaches 128 KiB.
The final write emits any remaining bytes after the decision.

**Parity decision.** This block compares n + 1 with two.

```nim
let friendCount = nextInt(inputData, scanPos)
if (friendCount + 1) mod 2 == 0:
  appendOutput("yes\n")
else:
  appendOutput("no\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The condition checks the full player count, including Sharmeen.
One append writes the complete answer line.
The last two lines flush the buffer at end of input.

## Complexity

The work splits into input parsing, the parity test, and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Decision | one operation | none |
| Output | one write per 128 KiB block | block buffer |

The decision phase does not grow with n.

The overall bounds:

| Measure | Big O |
|---|---|
| Time | O(I) for I input bytes |
| Space | O(I) for I input bytes |

Constructing two teams would cost O(n) work, so the parity test wins.

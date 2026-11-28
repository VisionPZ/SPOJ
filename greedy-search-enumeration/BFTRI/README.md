# BFTRI — Drawing Triangles with Brainf**k (SPOJ)

<https://www.spoj.com/problems/BFTRI/>

## Problem

Given a character and a size, print a triangle whose row `r` contains the character repeated `r` times. Repeat for each test case.

Input starts with `T`, the test count. Each following line holds one printable character and one integer size, separated by a space. Output the triangles one after another with no blank lines.

| item | bound |
|---|---|
| test count `T` | 1 to 99 |
| size `i` | 1 to 99 |
| character `c` | ASCII 33 to 126 |
| judge limit | 1000 ms, 1536 MB |

The notation `r` means the current row number, starting at one.

Sample input:

```
3
& 1
@ 3
? 5
```

Sample output:

```
&
@
@@
@@@
?
??
???
????
?????
```

## Idea

Rows grow one character at a time, like adding one block to each step of a staircase. The solution writes characters straight into one output buffer and flushes in large blocks. Each case costs the length of its triangle, and no geometry is stored.

A direct printer could write each character separately. Buffering avoids a system call per character and keeps the largest case fast.

## Why It Works

1. Row `r` must contain exactly `r` copies of the given character.
2. A nested loop walks rows from one to the size and columns from one to the row number.
3. Appending a newline after each row separates rows and test cases.
4. The buffer flushes after it reaches the block threshold, then once at the end.

| term | meaning |
|---|---|
| `triangleChar` | the printable character to repeat |
| `triangleSize` | the number of rows |
| `rowText` | the characters of one row |
| `outputBuffer` | the shared block of pending output |

A script expanded the sample and produced these row lengths.

| case | row lengths | characters printed |
|---|---|---|
| `& 1` | 1 | 1 |
| `@ 3` | 1, 2, 3 | 6 |
| `? 5` | 1, 2, 3, 4, 5 | 15 |

The totals match the sample output byte for byte.

## Code

**Input and scanning.** The reader loads the whole stream and provides two token readers.

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

proc nextVisibleChar(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = data[pos]
  pos += 1
```

The integer scanner skips the space after the character.
The character reader skips all whitespace.
Both readers share one cursor.

**Output buffering.** One buffer holds the pending triangle text.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Each call appends a row or a newline.
A flush clears the buffer after a large block.
The last flush handles the remainder.

**Triangle loop.** Each row builds its text and enters the buffer.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let triangleChar = nextVisibleChar(inputData, scanPos)
  let triangleSize = nextInt(inputData, scanPos)
  for rowIndex in 1 .. triangleSize:
    var rowText = ""
    for columnIndex in 1 .. rowIndex:
      rowText.add triangleChar
    appendOutput(rowText)
    appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The outer loop covers all test cases.
The inner loops emit one growing row at a time.
Newlines separate rows without extra spacing.

## Complexity

The program emits one character per printed cell.

| phase | time | space |
|---|---|---|
| input read | one pass over the token stream | one input string |
| triangle write | sum of row sizes per case | one row string |
| output | buffered blocks | one buffer |

| measure | Big O |
|---|---|
| time | O(T × i²) with maximum size `i` |
| space | O(i) for one row |

Writing each character unbuffered would add a system call per cell.

Buffered rows keep the largest case within the judge limit.

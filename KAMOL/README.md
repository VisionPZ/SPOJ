# KAMOL — Thanks for everything Kamol bhai! (SPOJ)

<https://www.spoj.com/problems/KAMOL/>

## Problem

The judge expects one fixed farewell line. Nothing is read from stdin, and the output bytes never change.

The contract holds a single required line and no input fields.

| item | bound |
|---|---|
| input | none |
| output | `GoodBye Kam0L Bhai` followed by a newline |
| judge limit | 1000 ms, 1536 MB |

The name contains a zero, not the letter O, and the final word starts with a capital B.

Sample output:

```
GoodBye Kam0L Bhai
```

This is the exact line the statement lists as output.

## Idea

A farewell card carries the same words every time, no matter who opens it. The program writes its fixed card and ignores stdin.

The real algorithm is a constant string write. Each run does one append and one flush, with no parsing at all. Reading and formatting numbers would add work that this task never needs.

One literal line is the whole solution.

## Why It Works

1. The statement defines one output string, so no computation can change it.
2. The string mixes capital letters, lowercase letters, a zero, and spaces.
3. Writing the literal preserves every one of those bytes.
4. A trailing newline matches the statement's output line.

Each name below serves one part of the write path.

| term | meaning |
|---|---|
| `inputData` | the stdin text, always unused here |
| `outputBuffer` | the single buffer that holds the line |
| `appendOutput` | the procedure that adds text and flushes blocks |

These names keep the write path easy to follow.

Script-generated example:

```
empty input -> GoodBye Kam0L Bhai
123 456 -> GoodBye Kam0L Bhai
```

The output stays the same for every input.

No rounding or bounds apply because no number is read. The block flush leaves the buffer empty after the single write.

## Code

**Input and buffered output.** The reader still consumes stdin, and the writer keeps one buffer.

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

All stdin lines are collected once. The buffer flushes only after reaching its block size. No scanner is needed for a task without numbers.

**Fixed line and final write.** The program appends the literal once, then flushes.

```nim
if inputData.len > 0:
  discard

appendOutput("GoodBye Kam0L Bhai")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Any incoming text has no effect on the answer. The newline is added as its own append. The final write clears the buffer.

## Complexity

Reading stdin is the only work that depends on input size.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin bytes | one input string |
| line write | one append | constant |
| output | one line | block buffer |

The answer itself takes constant time.

| measure | Big O |
|---|---|
| time | O(I) for I input bytes |
| space | O(I) for the input string |

I counts the bytes read from stdin.

Parsing tokens would add work that a fixed line never needs. Writing the literal once gives the answer.

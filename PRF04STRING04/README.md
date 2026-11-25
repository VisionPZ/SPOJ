# PRF04STRING04 — String - trim (SPOJ)

<https://www.spoj.com/problems/PRF04STRING04/>

## Problem

Read one line of text and print its words separated by one space. Drop every space before the first word and after the last word, and squeeze each inner run of whitespace down to one space.

The input is a single line of characters. Whitespace may appear anywhere, including long runs between words. The output is that same text with one line and single spaces between words.

| item | bound |
|---|---|
| input shape | one line of text |
| whitespace runs | any length |
| judge limit | 1000 ms, 1536 MB |

The longest whitespace run drives the design, not the word count.

The sample input:

```
      Lap trinh         can ban C             
```

The sample output:

```
Lap trinh can ban C
```

Both blocks above match the statement byte for byte, including the trailing spaces in the input.

## Idea

Treat a run of whitespace like a closed door: it opens the way to the next word, but only one space passes through. Scan the text once and keep a flag that says a space is waiting. Write that space only when another real character arrives.

The algorithm is a single character scan with a pending-space flag. Each character costs one comparison and at most one append, so the work is linear in the input length. Rebuilding the text with repeated string replacements would scan the same bytes many times and cost more.

One pass, one flag, and one output line solve the whole problem.

## Why It Works

1. Every non-whitespace character belongs to exactly one word.
2. Every whitespace run sits either at an edge or between two words.
3. A pending flag turns any length of run into one space.
4. The flag is written only when a later character exists, so trailing runs vanish.
5. A flag set before the first word is written only with that word, so leading runs vanish.

| term | meaning |
|---|---|
| `inputChar` | one character read from the full input text |
| `normalizedText` | the output text built so far |
| `pendingSpace` | true when whitespace was seen and a space is waiting |

The flag carries the whole state of the scan.

A script trace of the sample shows the visible numbers. The six leading spaces set no flag because the output is still empty. The runs of 9 and 1 spaces each add one separator.

```
word      run before it   output after writing the word
Lap       6 leading       Lap
trinh     1               Lap trinh
can       9               Lap trinh can
ban       1               Lap trinh can ban
C         1               Lap trinh can ban C
trailing  13              Lap trinh can ban C
```

The final trailing run of 13 spaces produces no extra space, which matches the sample answer.

No rounding or overflow guard is needed because the program only copies bytes.

## Code

**Input and output setup.** The reader loads all stdin into one string and defines the block writer.

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

The loop visits every line once and appends a newline after each.
The writer flushes only after the buffer reaches 131072 bytes.
No output is emitted per character.

**Whitespace collapse.** One pass turns every whitespace run into a single separator.

```nim
var normalizedText = ""
var pendingSpace = false
for inputChar in inputData:
  if inputChar == ' ' or inputChar == '\t' or inputChar == '\n' or inputChar == '\r':
    if normalizedText.len > 0:
      pendingSpace = true
  else:
    if pendingSpace:
      normalizedText.add ' '
      pendingSpace = false
    normalizedText.add inputChar

appendOutput(normalizedText)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The condition covers space, tab, newline, and carriage return.
The empty-output test removes leading and trailing runs.
The final flush writes the single answer line.

## Complexity

The scan visits each input character once and builds one output line.

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | one input string |
| whitespace collapse | one pass over characters | one output string |
| output | one buffered write | block buffer |

Each phase runs once and keeps only one main string.

| measure | Big O |
|---|---|
| time | O(L) for input length L |
| space | O(L) for the input and output strings |

Repeated replace calls would rescan the text and cost more than one linear pass.
A single flag keeps the whole job linear.

# SEC01 — Welcome our new VC (SPOJ)

<https://www.spoj.com/problems/SEC01/>

## Problem

The program prints one fixed university name and reads no input. The judge compares that single line with the required text.

The input contract is empty. The output contract is one line containing the university name without quotes.

The limits from the statement:

| Item | Bound |
|---|---|
| Input | none |
| Output | one line of 31 characters |
| Judge limit | 1000 ms, 1536 MB |

No value depends on input bytes, so the answer is a constant.

The statement gives no sample block. The required output line appears below.

```
```

```
Sylhet International University
```

## Idea

A fixed sign needs no input; the program hangs the same sign on every run. The algorithm prints one constant string, so it performs no parsing. The output buffer collects the line and writes it once. A program that analyzed input would add work without changing the text.

The cost stays constant after the input read.

## Why It Works

1. The problem defines one required output line and no input contract.
2. A literal string emits those exact bytes, including both space characters.
3. The trailing newline matches the sample line shape used by the judge.
4. The hand scanner consumes stray bytes without changing the output.

The terms used by the program:

| Term | Meaning |
|---|---|
| `inputData` | string holding all bytes read from stdin |
| `scanPos` | index of the next unread input byte |
| `nextInt` | hand scanner that skips non-digits |
| `outputBuffer` | string that collects the answer line |
| `appendOutput` | procedure that appends text and flushes blocks |

The scanner exists for uniform input handling across this repository.

A script-traced example from `gen.py`:

```
words ['Sylhet', 'International', 'University']
output Sylhet International University
```

Joining the three words reproduces the required line.

## Code

**Input buffer and hand scanner.** This block reads stdin and defines the index scanner.

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
    let digit = ord(data[position]) - firstDigitValue
    if value > (high(int) - digit) div 10:
      value = high(int)
    else:
      value = value * 10 + digit
    position += 1
  return value
```

One readLine loop collects stdin into `inputData`.
The scanner advances `scanPos` by index, without token objects.
The guard caps long digit runs at `high(int)`.
The call below discards any stray numeric bytes.

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
The final write emits any remaining bytes after the call.

**Constant answer.** This block emits the university name.

```nim
discard nextInt(inputData, scanPos)
appendOutput("Sylhet International University\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The scanner consumes stray input bytes before the answer.
One append writes the whole required line.
The last two lines flush the buffer at end of input.

## Complexity

The work splits into input reading, the constant answer, and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Answer | constant work | none beyond the string |
| Output | one write per 128 KiB block | block buffer |

The judged input is empty, so the read phase costs no bytes.

The overall bounds:

| Measure | Big O |
|---|---|
| Time | O(I) for I input bytes |
| Space | O(I) for I input bytes |

Parsing input into tokens would add allocation, so direct printing wins.

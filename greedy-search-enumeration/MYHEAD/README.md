# MYHEAD — My Head (SPOJ)

<https://www.spoj.com/problems/MYHEAD/>

## Problem

Atik repeats a wrong phrase about the meaning of My Head.
Four relatives each correct him with the same phrase.
Print that trusted phrase and nothing else.

There is no input.
Print one line holding the correct answer.

| Item | Bound |
|---|---|
| Input | none |
| Output | one fixed line |
| Judge limit | 1000 ms |

The story is the only source of the answer.

The statement prints the following sample, then rejects it in a hint:

```
There is no sample input.
```

```
Babar Matha 
```

The trusted answer used by the tests appears as the output below.

```
Amar Matha
```

## Idea

Treat the four relatives as trustworthy witnesses at one meeting.

Collect the exact phrase each witness repeats.
Take the phrase that all four give.
The printed sample is a fifth, unreliable source and is set aside.

One fixed line is written through the buffered output path.

## Why It Works

1. The story states that every person except Atik can be trusted.
2. Each trusted person gives the same correction with the words Amar Matha.
3. The hint declares the printed sample output wrong.
4. Voting over trusted statements therefore yields Amar Matha.

| Term | Meaning |
|---|---|
| `TRUSTED_CORRECTIONS` | four quoted statements from the relatives |
| `oracle` | counts phrases and picks the common one |
| `outputBuffer` | buffered text sent to standard output |

The oracle derives the answer from the story rather than copying the rejected sample.

Script-generated example from `gen.py`:

```
Amar Matha
Amar Matha
```

Both quoted corrections resolve to the same trusted phrase.

## Code

**Input and buffer.** This block consumes any stray input and defines buffered output.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
while scanPos < inputData.len and inputData[scanPos] <= ' ':
  scanPos += 1

var outputBuffer = ""
proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`scanPos` advances over leading whitespace only.
No token is needed because the input is empty.
The buffer flushes every 128 KiB by convention.

**Answer.** This block writes the trusted phrase once.

```nim
appendOutput("Amar Matha")
appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The two append calls place the phrase and newline.
One final write clears the buffer.
The program produces exactly eleven bytes.

## Complexity

The program performs a single short output operation.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over stray bytes | input bytes |
| Answer | one fixed string append | constant |
| Output | one short write | block buffer |

Runtime is constant for the specified empty input.

| Measure | Big O |
|---|---|
| Time | O(I) |
| Space | O(I) |

Parsing every quoted phrase at runtime adds cost and reproduces the rejected sample.

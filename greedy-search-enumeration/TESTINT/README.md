# TESTINT — Test 1 (SPOJ)

<https://www.spoj.com/problems/TESTINT/>

## Problem

Read two natural numbers, one on each line, and print their sum. There is no test count and no other work.

The input holds exactly two numbers, each at most 200. The output holds one number.

| Item | Bound |
|---|---|
| First number | 0 to 200 |
| Second number | 0 to 200 |
| Judge limit | 1000 ms, 1536 MB |

The sample:

```
2
3
```

```
5
```

## Idea

Add the two numbers once. The whole program is one read, one addition, and one write.

The program reads the whole input into one string, scans the two numbers by index, and appends their sum to one output buffer. Building a token list would allocate objects for two numbers and change nothing.

One addition and one buffered write finish the case.

## Why It Works

1. The input is a stream of digits. A hand scanner turns each run of digits into a value without a substring.
2. The spec gives no test count, so the driver reads exactly two values and stops.
3. One output line is never large, but one buffer keeps the write path the same as in every other solution here.

| Term | Meaning |
|---|---|
| `inputData` | the whole input read into one string |
| `scanPos` | the index of the next digit to read |
| `outputBuffer` | the single string that holds the answer |

The two numbers decide the answer, and nothing else does.

A traced run of the sample:

```
scanPos 0 -> skip newline -> digits "2"  -> firstValue = 2
scanPos 2 -> skip newline -> digits "3"  -> secondValue = 3
appendOutput("5") -> outputBuffer = "5"
final stdout.write -> "5\n"
```

The trace prints 5, which matches the sample output.

## Code

**Input read.** One line at a time, appended to one string.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

`readLine` works on the judge compiler, which has no whole-stream read. The loop costs one pass over the input bytes.

**Digit scanner.** Each call advances `scanPos` past the next integer.

```nim
proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The `var` parameter keeps the position between calls. A digit byte becomes `int(data[pos]) - 48`, with no parse call.

**Driver.** Two reads, one addition, one write.

```nim
let firstValue = nextInt(inputData, scanPos)
let secondValue = nextInt(inputData, scanPos)
appendOutput($(firstValue + secondValue))
outputBuffer.add '\n'
stdout.write outputBuffer
```

The driver reads exactly two integers, as the contract demands. The final write covers the one answer line.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the few input bytes | input bytes |
| Two scans | one pass over the digits | constant |
| Output | one write of one line | one buffer |

The input size bounds the whole run.

| Measure | Big O |
|---|---|
| Time | O(N) for N input bytes |
| Space | O(N) for the input buffer |

A token-splitting reader would do the same work with extra allocation. One pass over the bytes is the whole algorithm.

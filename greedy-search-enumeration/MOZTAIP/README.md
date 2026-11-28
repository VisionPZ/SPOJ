# MOZTAIP — The ACM ICPC Problem (SPOJ)

<https://www.spoj.com/problems/MOZTAIP/>

## Problem

A team tried to print a fixed line and received a wrong answer. Print the literal characters the judge expects, with each escape pair written as a slash and a letter. No tab character and no line break belong in the output.

There is no input. The output is the 26-character text shown below. The statement's example output of "Hello World" is a leftover placeholder.

| item | bound |
|---|---|
| input | none |
| output length | 26 characters |
| judge limit | 1000 ms, 1536 MB |

The two escape pairs are the whole trick.

Sample input: (empty)

Sample output:

```
Competitive\tprogramming\n
```

## Idea

Think of copying a sign letter by letter instead of reading its meaning. A backslash followed by `t` is two marks on the paper, not a tab. Print the 26 characters as one constant string. No search, parsing, or arithmetic is needed.

The whole program is one buffered write, so the cost is constant. Treating the escapes as control characters produces the wrong answer.

## Why It Works

1. The statement writes the required line with a slash before `t` and a slash before `n`.
2. A literal print of those pairs emits four characters for the two pairs.
3. Printing a real tab or a real newline emits only two control characters and fails.
4. The judge compares bytes, so the byte count must be 26.

| term | meaning |
|---|---|
| `requiredLine` | the 26-character constant to print |
| `outputBuffer` | block buffer that holds the constant |

Counting characters gives 11 for Competitive, 2 for the first pair, 11 for programming, and 2 for the last pair.

| part | characters |
|---|---|
| Competitive | 11 |
| backslash and t | 2 |
| programming | 11 |
| backslash and n | 2 |
| total | 26 |

The total matches the required output length.

## Code

**Constant and reader.** The source defines the exact text and still drains stdin.

```nim
const flushBlockBytes = 1 shl 17
const requiredLine = "Competitive\\tprogramming\\n"

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

Doubled backslashes in the literal produce single backslashes in the output. Reading stdin does not affect the answer.

**Buffered write.** One append and one flush emit the whole answer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

appendOutput(requiredLine)
stdout.write outputBuffer
outputBuffer.setLen 0
```

The final flush emits the constant. No newline is appended after it.

## Complexity

No input is read and no loop depends on a bound.

| phase | time | space |
|---|---|---|
| input read | one empty line | one input string |
| output | one buffered write | block buffer |

Each phase runs once.

| measure | Big O |
|---|---|
| time | O(1) |
| space | O(1) |

Any algorithm that scans or computes would add work for no gain, so a constant write is optimal here. That single write sets the cost.

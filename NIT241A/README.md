# NIT241A — Hello NIT OJ (SPOJ)

<https://www.spoj.com/problems/NIT241A/>

## Problem

Print the greeting line `Hello NIT OJ.` and nothing else. The statement warns that any extra output causes a wrong answer.

There is no input. The output is one line.

| item | bound |
|---|---|
| input | none |
| output | one fixed line |
| judge limit | 1000 ms, 1536 MB |

The whole job is one write to standard output.

Sample input:

```
```

Sample output:

```
Hello NIT OJ.
```

## Idea

A name tag that already reads the answer needs no work. The program drains standard input, then writes the greeting string exactly as given.

Draining input keeps the run clean when the judge pipes a file in, and the literal guarantees the punctuation, the single spaces, and the final period.

Takeaway: when the answer is a constant, just print it.

## Why It Works

1. The statement fixes the output text, so a string literal is the exact answer.
2. Reading every line first means no unread input is left behind.
3. One `stdout.write` call emits the line with its newline.
4. Nothing else is printed, so the byte match is exact.

For the sample, the empty input still produces the one required line.

The period after `OJ` is part of the string; dropping it would fail.

## Code

**Input draining.** All lines are read and thrown away.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

discard inputData.len
stdout.write "Hello NIT OJ.\n"
```

The loop ends when standard input closes.
The `discard` line marks the collected text as unused on purpose.
The write contains the greeting and its newline.

## Complexity

The program touches each input character once and writes 13 bytes.

| phase | time | space |
|---|---|---|
| read input | one pass over the file | one string |
| output | one write | none |

| measure | Big O |
|---|---|
| time | O(input size) |
| space | O(input size) |

With no input the work is constant.

Takeaway: a constant answer runs in constant time.

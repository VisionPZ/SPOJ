# KAMOL — Thanks for everything Kamol bhai! (SPOJ)

<https://www.spoj.com/problems/KAMOL/>

## Problem

Print one fixed line of text and collect the point. The statement gives the exact sentence to echo, and nothing else.

There is no input at all. The output is the single line `GoodBye Kam0L Bhai`.

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
GoodBye Kam0L Bhai
```

## Idea

A sign that already says the answer needs no reading. The program drains standard input, then writes the farewell string.

Draining input keeps the run clean on judges that pipe a file into the program. No parsing, no math, no formatting choices.

Takeaway: when the answer is a constant, just print it.

## Why It Works

1. The statement fixes the output text, so a string literal is the exact answer.
2. Reading every line first means the program never leaves unread input behind.
3. One `stdout.write` call emits the line with its final newline.
4. Nothing else is printed, so the output matches byte for byte.

For the sample, the empty input still produces the one required line.

Extra trailing spaces or a missing newline would break the match, so the literal ends with `\n` and nothing follows it.

## Code

**Input draining.** All lines are read and thrown away.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

discard inputData.len
stdout.write "GoodBye Kam0L Bhai\n"
```

The loop ends when standard input closes.
The `discard` line marks the collected text as unused on purpose.
The write contains the sentence and its newline.

## Complexity

The program touches each input character once and writes 19 bytes.

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

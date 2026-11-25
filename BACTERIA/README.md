# BACTERIA — Custom Test (SPOJ)

<https://www.spoj.com/problems/BACTERIA/>

## Problem

The judge supplies an empty input file and accepts any output. Write a program that reads all input and prints nothing.

Input is empty: zero bytes. Output may be any bytes, but only the first 1024 KB are displayed. The verdict is accepted and scores zero points.

| Item | Bound |
|---|---|
| Input bytes | 0 |
| Accepted output | any bytes, 1024 KB displayed |
| Time limit | 30 s |
| Memory | 1536 MB |
| Source | 50000 bytes |

The statement gives no sample; both the input and a valid output are empty.

```
```

```
```

## Idea

A microphone check before a concert: the device is on, yet nobody speaks. The program opens the input stream, consumes whatever arrives, and writes nothing.

The read loop appends each line to one string. With no lines present, the loop exits immediately and no bytes are emitted.

One pass over the input bytes is the whole algorithm; here that pass costs nothing.

## Why It Works

1. The judge file has zero bytes, so `readLine` returns false on the first call.
2. Printing nothing stays within the 1024 KB display cap.
3. No parsing occurs, so the program needs no integer scanner and no output buffer.

| Term | Meaning |
|---|---|
| `inputData` | the single string that would hold every input line |
| `inputLine` | the most recent line returned by `readLine` |
| `readLine` | the call that consumes one line from standard input |

A script-generated view of the five cases from `gen.py`:

```
1_sample.txt   0 input bytes   0 output bytes
2_edges.txt    0 input bytes   0 output bytes
3_wide.txt     0 input bytes   0 output bytes
4_random.txt   0 input bytes   0 output bytes
5_io.txt       0 input bytes   0 output bytes
```

Every generated case is empty on both sides, which matches the statement.

## Code

**Input consumption.** One loop reads all lines and emits no bytes.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

The loop runs once per input line, which is zero times here. No output buffer exists, so a stale flush cannot occur. The cost is one pass over the input stream.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over zero bytes | one string |
| Output | no writes | none |

The empty input makes both phases trivial.

| Measure | Big O |
|---|---|
| Time | O(1) for an empty file |
| Space | O(1) |

A program that formatted feedback would add work without changing the verdict. Writing nothing is the smaller solution.

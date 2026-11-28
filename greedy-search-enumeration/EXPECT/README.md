# EXPECT — Life, the Universe, and Everything (Interactive) (SPOJ)

<https://www.spoj.com/problems/EXPECT/>

## Problem

The judge sends one integer per line, one at a time. Copy each number back and stop immediately after copying 42.

Input arrives on standard input as integers of one or two digits. Output goes to standard output as the same integer followed by a newline. Each answer must reach the judge before the next number is read.

| Item | Bound |
|---|---|
| Number of lines | until the line containing 42 |
| Digits per number | 1 or 2 |
| Stop token | 42 |
| Judge limit | 1000 ms, 1536 MB |

The sample from the statement:

```
3
15
42
```

```
3
15
42
```

## Idea

A relay operator repeats each number over the radio before listening again, then signs off at 42.

The program reads one line, scans its digits into an integer, writes that integer with a newline, and flushes. If the value is 42, it exits. Each line costs a scan of at most two digits and one flush.

Holding answers in a buffer would delay every reply until exit, so the interactive judge would wait forever.

## Why It Works

1. `readLine` returns as soon as one newline arrives, so the program never waits for end of file.
2. Scanning the digits and writing the integer reproduces the number token exactly.
3. `flushFile` sends the bytes to the judge before the next number is requested.
4. The check for 42 ends the session on the required stop token.

| Term | Meaning |
|---|---|
| `inputLine` | one number line supplied by the judge |
| `value` | the integer parsed from that line |
| `digitIndex` | the position scanned inside the line |
| `flushFile` | the call that pushes the answer out at once |

A script-traced run of the sample case from `gen.py`:

```
line "3"   value 3   write "3\n"   flush   continue
line "15"  value 15  write "15\n"  flush   continue
line "42"  value 42  write "42\n"  flush   stop
```

The three flushed lines match the sample output in order.

## Code

**Line relay.** One read, one write, and one flush per number.

```nim
var inputLine = ""
while readLine(stdin, inputLine):
  var value = 0
  var digitIndex = 0
  while digitIndex < inputLine.len and inputLine[digitIndex] >= '0' and inputLine[digitIndex] <= '9':
    value = value * 10 + int(inputLine[digitIndex]) - 48
    digitIndex += 1
  stdout.write $(value)
  stdout.write "\n"
  flushFile(stdout)
  if value == 42:
    break
```

The loop runs until the value 42, which the judge always sends. Omitting the flush is the trap that stalls an interactive run. The inner scan touches at most two digits per line.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Read one line | one pass over at most two digits | one line |
| Write and flush | one line to the judge | none |
| Stop check | one comparison | none |

The per-line cost stays constant because the numbers are short.

| Measure | Big O |
|---|---|
| Time | O(total lines read) |
| Space | O(1) |

A buffered bulk write would keep every answer hidden until exit, so the judge would time out. Per-line flushing avoids that failure.

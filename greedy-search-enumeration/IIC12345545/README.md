# IIC12345545 — COMP (SPOJ)

<https://www.spoj.com/problems/IIC12345545/>

## Problem

Read one number and print its first digit. The number arrives as text, so the leading digit is simply the first digit character in the stream.

The input holds a single number N with 1 < N < 1000. The output is one digit on its own line.

| item | bound |
|---|---|
| N | 1 < N < 1000 |
| output | one digit |
| judge limit | 1000 ms, 1536 MB |

A single character scan answers the question.

Sample input:

```
123
```

Sample output:

```
1
```

## Idea

Reading the first name on a list does not require reading the whole list. The program skips every character that is not a digit, then prints the first digit it meets.

No number is ever built, so no integer type is involved and no overflow can happen, even for absurdly long input.

Takeaway: keep the answer as a character, not a number.

## Why It Works

1. A first digit is the leftmost digit character of the number.
2. Characters before it are only spaces or newlines, which the scan skips.
3. Comparing against `'0'` and `'9'` recognises digits exactly.
4. Printing that character gives the digit with no conversion.

For the sample, the scan stops at `1` and prints it.

If the input held no digit at all, the program prints `0` as a safe fallback.

## Code

**Input reading.** The whole file is loaded into one string.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

One pass loads every line, so later scans use plain indexes.

**First digit scan.** The cursor stops at the first digit.

```nim
var scanPos = 0
while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
  scanPos += 1

if scanPos < inputData.len:
  stdout.write inputData[scanPos]
else:
  stdout.write '0'
stdout.write '\n'
```

The skip loop moves past spaces and newlines.
The found character is written directly.
The final newline ends the line.

## Complexity

The scan walks the input once and stops at the first digit.

| phase | time | space |
|---|---|---|
| read input | one pass over the file | one string |
| scan | stops at the first digit | none |
| output | one write | none |

| measure | Big O |
|---|---|
| time | O(input size) |
| space | O(input size) |

Converting the whole number to an integer would need big-number code for long inputs.

Takeaway: the first digit is a character lookup, not arithmetic.

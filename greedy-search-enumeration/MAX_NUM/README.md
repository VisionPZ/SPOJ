# MAX_NUM — finding maximum possible number (SPOJ)

<https://www.spoj.com/problems/MAX_NUM/>

## Problem

Delete exactly k digits from a digit string and keep the remaining digits in their original order. Return the largest possible number as a digit string, including any leading zeros.

Input starts with T, the number of test cases. Each of the next T lines holds a digit string n and an integer k. Output one answer per line; when k equals the length of n, output an empty line.

| item | bound |
|---|---|
| test cases T | up to 1000 |
| digits in n | 1 to 100000, leading zeros allowed |
| deletions k | 0 to length of n |
| judge limit | 407 ms, 1536 MB |

The output is a string of digits, so a leading zero stays in place.

Sample input:

```
2
1223 2
8756 2
```

Sample output:

```
23
87
```

## Idea

A larger digit only helps when it can move ahead of a smaller one, like a taller student stepping in front of a shorter one in a queue. Use a monotonic stack that drops a smaller digit whenever a larger digit arrives and deletions remain.

The stack keeps digits in non-increasing order. Each digit enters once and leaves once, so the cost is linear in the number of digits. A naive search tries every subset of kept digits and grows exponentially with the string length.

The stack builds the lexicographically largest subsequence of the required length.

## Why It Works

1. Keeping digits in order means the answer is a subsequence of n.
2. A smaller digit before a larger one can be removed to improve the result.
3. The stack removes such a digit immediately, spending one deletion.
4. After all digits are seen, any unused deletions remove the smallest trailing digits.
5. The remaining stack is the largest subsequence of length len(n) minus k.

| term | meaning |
|---|---|
| `numberText` | the digit string n read from the input |
| `deleteCount` | deletions still available during the scan |
| `keptDigits` | stack holding the digits kept so far |
| `keptLength` | current stack depth |
| `resultText` | final digit string written to the buffer |

A trace of `1223` with k = 2 from the generator:

| digit | action | stack | deletions left |
|---|---|---|---|
| 1 | push | 1 | 2 |
| 2 | pop 1, push 2 | 2 | 1 |
| 2 | push | 2 2 | 1 |
| 3 | pop 2, push 3 | 2 3 | 0 |

The trace leaves `23`, which matches the sample answer.

## Code

**Input and parsing.** The reader loads all of stdin and provides two hand scanners.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc nextDigitRun(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  let runStart = pos
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    pos += 1
  return data[runStart .. pos - 1]
```

The scanner skips separators before each token.
`nextDigitRun` preserves leading zeros because it returns raw digits.
Both scanners stop at the end of the input string.

**Stack and output.** The loop builds one answer per test case.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let numberText = nextDigitRun(inputData, scanPos)
  var deleteCount = nextInt(inputData, scanPos)
  if deleteCount >= numberText.len:
    appendOutput("")
    outputBuffer.add '\n'
    continue
  var keptDigits = newSeq[char](numberText.len)
  var keptLength = 0
  for digitChar in numberText:
    while keptLength > 0 and deleteCount > 0 and keptDigits[keptLength - 1] < digitChar:
      keptLength -= 1
      deleteCount -= 1
    keptDigits[keptLength] = digitChar
    keptLength += 1
  var resultText = ""
  for keptIndex in 0 .. keptLength - deleteCount - 1:
    resultText.add keptDigits[keptIndex]
  appendOutput(resultText)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Full deletion writes an empty line and skips the stack.
Every other answer takes the prefix of the required length.
The buffer flushes once after the loop, not per digit.

## Complexity

The scan visits each digit once and writes one answer per case.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| stack scan | one push and one pop per digit | array of digits |
| output | one line per case | block buffer |

The stack phase dominates the runtime.

| measure | Big O |
|---|---|
| time | O(len(n)) per test case |
| space | O(len(n)) for the stack |

Trying every kept subset would cost exponential time instead of linear time.
The linear stack keeps long digit strings practical.

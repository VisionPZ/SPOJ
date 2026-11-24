## Problem

Read a count, then that many integers n. For each n, print the smallest positive integer whose digit sum equals n and whose value is divisible by n. Print one answer per line, without leading zeros.

| Quantity | Bound |
| --- | --- |
| Test cases | 50 or fewer |
| Each n | 1 to 1000 |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |
| Source size | 4096 bytes |

The bound on n fixes the state table, and the source limit keeps the program compact.

## Idea

Build the answer digit by digit with a queue that visits shorter numbers first, called a breadth-first search. Each state holds a remainder and a digit sum, and ten transitions per state replace a scan of every candidate integer. At most n(n+1) states exist, so one flat table bounds the work.

## Why It Works

Appending digit d to a number with remainder r gives remainder (10r + d) mod n. The digit sum grows by d, and a state never needs a sum above n. The queue holds numbers in numeric order within each length layer, so the first target state gives the smallest answer. Revisiting a state cannot help, because the earlier number is smaller.

The state index mixes a remainder with a digit sum:

- `remainder` runs from 0 to n−1.
- `digitSum` runs from 0 to n.
- `stride` equals 1001, which is one more than the largest n.

The trace below lists the states with digit sum 10 in queue order for n = 10.

| digit string | remainder mod 10 | digit sum |
| --- | --- | --- |
| 19 | 9 | 10 |
| 28 | 8 | 10 |
| 37 | 7 | 10 |
| 46 | 6 | 10 |
| 55 | 5 | 10 |
| 64 | 4 | 10 |
| 73 | 3 | 10 |
| 82 | 2 | 10 |
| 91 | 1 | 10 |
| 190 | 0 | 10 |

The first state with remainder 0 belongs to 190, so the answer for 10 is 190.

## Code

The constants fix the table size and the buffer flush size.

```nim
{.passC: "-O2".}
{.push checks: off.}
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxN = 1000
const stride = 1001
const maxStates = stride * maxN
```

The input loop reads every line once, and the scanner walks that one buffer by index.

```nim
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

Six arrays are allocated once. The mark array avoids clearing tables for each case.

```nim
var visitMark = newSeq[int32](maxStates)
var parentState = newSeq[int32](maxStates)
var parentDigit = newSeq[int8](maxStates)
var bfsQueue = newSeq[int32](maxStates + 16)
var remainderTable = newSeq[int16](maxN * 10 + 10)
var caseMark = int32(0)
```

The answer builder follows parent links back to the first digit, then reverses them.

```nim
proc buildAnswer(startState: int): string =
  var digits: seq[int8] = @[]
  var cur = startState
  while cur >= 0:
    digits.add parentDigit[cur]
    cur = int(parentState[cur])
  var answerText = ""
  for k in 0..<digits.len:
    answerText.add char(firstDigitValue + int(digits[digits.len - 1 - k]))
  return answerText
```

The search seeds digits 1 to 9, then expands each state with digits 0 to 9. The break on nextSum skips sums above n, and the visit mark keeps the queue bounded.

```nim
proc solve(target: int): string =
  caseMark += 1
  for i in 0..<remainderTable.len:
    remainderTable[i] = int16(i mod target)
  var head = 0
  var tail = 0
  for digit in 1..9:
    if digit > target: break
    let remain = int(remainderTable[digit])
    let state = remain * stride + digit
    if visitMark[state] == caseMark: continue
    visitMark[state] = caseMark
    parentState[state] = -1
    parentDigit[state] = int8(digit)
    if remain == 0 and digit == target: return buildAnswer(state)
    bfsQueue[tail] = int32(state)
    tail += 1
  while head < tail:
    let state = int(bfsQueue[head])
    head += 1
    let remain = state div stride
    let digitSum = state mod stride
    for digit in 0..9:
      let nextSum = digitSum + digit
      if nextSum > target: break
      let nextRemain = int(remainderTable[remain * 10 + digit])
      let nextState = nextRemain * stride + nextSum
      if visitMark[nextState] == caseMark: continue
      visitMark[nextState] = caseMark
      parentState[nextState] = int32(state)
      parentDigit[nextState] = int8(digit)
      if nextRemain == 0 and nextSum == target: return buildAnswer(nextState)
      bfsQueue[tail] = int32(nextState)
      tail += 1
  return ""
```

The output buffer flushes by size, not by line. The final flush writes any remaining bytes.

```nim
var outputBuffer = ""
proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for j in 0..<caseCount:
  let target = nextInt(inputData, scanPos)
  appendOutput(solve(target))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

## Complexity

Input scanning costs O(bytes). Table setup costs O(10 maxN) per case, and reconstruction costs O(answer length). The search visits at most n(n+1) states with ten transitions each, so a case costs O(n²) time and O(n²) space. The total is O(t n²) time and O(n²) space, with about 17 MB of arrays. Enumerating integers up to the answer instead can take exponential time in the answer length.

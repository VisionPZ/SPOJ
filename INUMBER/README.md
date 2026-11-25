# INUMBER — Interesting number (SPOJ)
<https://www.spoj.com/problems/INUMBER/>

## Problem

For a given n, find the smallest positive integer divisible by n whose digits add up to n. The answer may need many digits, so guessing numbers one by one wastes time.

The first line holds a test count t of at most 50. Each following line holds one integer n from 1 to 1000. Print the required number per line, without leading zeros.

The judge limits are:

| Item | Value |
| --- | --- |
| Test cases t | at most 50 |
| Each n | 1 to 1000 |
| Time limit | 7 s |
| Memory limit | 1536 MB |
| Source size | 4096 bytes |

The bound on n fixes the state table, and the source limit keeps the program compact.

The sample input reads:

```text
2
1
10
```

The sample output reads:

```text
1
190
```

## Idea

Build the answer digit by digit, like trying shorter lock codes before longer ones. A breadth-first search (a queue that visits shorter numbers first) keeps a state of remainder and digit sum. Appending one digit updates both in constant time, so ten transitions replace a scan of every candidate integer. At most n(n+1) states exist, and the first target state gives the smallest number. Each case costs O(n²) time. Testing integers in order can take time exponential in the answer length. Takeaway: search states, not numbers.

## Why It Works

1. Appending digit d to a number with remainder r gives remainder `(10*r + d) mod n`.
2. The digit sum grows by d, and no state needs a sum above n.
3. The queue holds numbers in numeric order within each length layer, so the first target state is smallest.
4. Revisiting a state cannot help, because the earlier number reaching it is smaller.
5. The state index mixes remainder with digit sum, with `stride = 1001` separating the two parts.
6. Seeds run from digit 1 to 9, so printed answers never start with zero.
7. A case mark avoids clearing the visit table for every test case.

The table defines the terms.

| Term | Meaning |
| --- | --- |
| `remainder` | current value modulo the target n |
| `digitSum` | sum of digits used so far |
| `state` | `remainder * stride + digitSum` |
| `caseMark` | stamp that marks states visited in one case |

These four terms define one queue state.

A script listed states with digit sum 10 in queue order for n = 10.

| Digit string | Remainder mod 10 | Digit sum |
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

**Constants.** The table sizes follow from the largest allowed n.

```nim
{.passC: "-O2".}
{.push checks: off.}
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxN = 1000
const stride = 1001
const maxStates = stride * maxN
```

`stride` is one more than the largest n. `maxStates` bounds both the visit table and the queue. The pragmas remove checks from the hot search loop.

**Input and scanner.** The program slurps input once and walks it by index.

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

The read loop appends one newline per input line. The scanner skips separators and consumes digits in place. Parsing one number visits each digit once.

**Persistent arrays.** Six arrays are allocated once for all cases.

```nim
var visitMark = newSeq[int32](maxStates)
var parentState = newSeq[int32](maxStates)
var parentDigit = newSeq[int8](maxStates)
var bfsQueue = newSeq[int32](maxStates + 16)
var remainderTable = newSeq[int16](maxN * 10 + 10)
var caseMark = int32(0)
```

`visitMark` replaces clearing the whole table per case. `parentState` and `parentDigit` remember the path back to the first digit. `remainderTable` holds remainders for values up to ten times n. The arrays use narrow integer types to cap memory.

**Answer reconstruction.** The program follows parent links, then reverses the digits.

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

The walk runs once per output digit. Reversing gives the number in normal order. The result has no leading zeros because seeds start at digit 1. Reconstruction costs O(answer length).

**Breadth-first search.** Seeds use digits 1 to 9, then each state expands with digits 0 to 9.

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

The break on `nextSum` skips sums above the target. The visit mark keeps the queue bounded. Division and modulo recover the two halves of a state. The first target state ends the search immediately.

**Driver.** The loop writes each answer and flushes output by size.

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

The loop runs exactly `caseCount` times. Flushing by size avoids one write per answer. The final flush emits any remaining bytes.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| Scan input | O(bytes) | O(input bytes) |
| Build remainder table | O(10 n) | O(10 n) |
| Search states | O(n²) | O(n²) |
| Reconstruct answer | O(answer length) | O(answer length) |

The state search dominates one case.

Each state has at most ten outgoing digit transitions.

| Measure | Bound |
| --- | --- |
| Per case | O(n²) time |
| Per case | O(n²) space |
| All cases | O(t n²) time |

The arrays hold about 17 MB. Testing integers up to the answer instead can take exponential time in the answer length.

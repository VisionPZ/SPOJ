# KVAR — Kevin likes array (SPOJ)

<https://www.spoj.com/problems/KVAR/>

## Problem

An array is beautiful when every out-of-order pair occupies neighboring spots. Report `YES` or `NO` for each test case.

The first input line holds the number of test cases, `T`. Each case starts with `N`, the array length, followed by `N` values `A[i]`. Print one verdict per case.

| item | bound |
|---|---|
| test cases `T` | 1 to 10 |
| array length `N` | 1 to 100 |
| value `A[i]` | 1 to 100 |
| judge limit | 1000 ms, 1536 MB |

An inversion is a pair `i < j` with `A[i] > A[j]`. A local inversion is a spot `i` with `A[i] > A[i+1]`.

Sample input:

```
4
1
1
2
2 1
3
3 2 1
4
1 3 2 4
```

Sample output:

```
YES
YES
NO
YES
```

The third array has two inversions at distance one and one at distance two.

## Idea

A distant inversion always hides a neighboring inversion on the walk between the two spots, like a long detour that still crosses a nearby turn. Store the smallest value to the right of each spot and compare it with the current value. This suffix minimum replaces a full pair count with one backward pass. Counting every pair costs O(N^2) per case, while the pass costs O(N). A case is beautiful exactly when no value beats any spot two or more places to its right.

## Why It Works

1. Each local inversion is also an inversion, so the two counts match only when all inversions are local.
2. If `A[i] > A[j]` with `j >= i+2`, the array is not beautiful.
3. The smallest value at positions `i+2` onward is the suffix minimum at `i+2`.
4. Comparing `A[i]` with that minimum tests every distant partner at once.
5. Checking all `i` up to `N-3` therefore decides the case.

| term | meaning |
|---|---|
| `values` | the array for one case |
| `suffixMinimum` | smallest value from a spot onward |
| `beautiful` | true when no distant inversion exists |
| `leftIndex` | spot being compared with its suffix |

The comparison table for the last sample case uses the array `1 3 2 4`.

| leftIndex | A[leftIndex] | suffixMinimum[leftIndex + 2] | result |
|---|---|---|---|
| 0 | 1 | 2 | keep |
| 1 | 3 | 4 | keep |

No value beats a spot two or more places away, so the verdict is `YES`.

## Code

**Input and scanning.** The hand reader loads every test value into one buffer.

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
```

The scanner skips whitespace between numbers.
It builds each value one digit at a time.
The buffer grows once for the whole input.

**Suffix test and verdict.** One backward pass builds the minima, then one forward pass decides.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let elementCount = nextInt(inputData, scanPos)
  var values = newSeq[int](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    values[elementIndex] = nextInt(inputData, scanPos)
  var suffixMinimum = newSeq[int](elementCount + 1)
  suffixMinimum[elementCount] = 2147483647
  var reverseIndex = elementCount - 1
  while reverseIndex >= 0:
    if values[reverseIndex] < suffixMinimum[reverseIndex + 1]:
      suffixMinimum[reverseIndex] = values[reverseIndex]
    else:
      suffixMinimum[reverseIndex] = suffixMinimum[reverseIndex + 1]
    reverseIndex -= 1
  var beautiful = true
  for leftIndex in 0 .. elementCount - 3:
    if values[leftIndex] > suffixMinimum[leftIndex + 2]:
      beautiful = false
  if beautiful:
    appendOutput("YES\n")
  else:
    appendOutput("NO\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The sentinel at index `N` is larger than every allowed value.
Arrays shorter than three spots skip the forward loop.
Verdicts collect in the output buffer and flush once.

## Complexity

Each case reads its array, builds one suffix table, and scans it.

| phase | time | space |
|---|---|---|
| input read | one pass over all values | one input string |
| suffix table | one backward pass over `N` | array of `N` integers |
| verdict | one forward pass over `N` | constant |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| time per case | O(N) |
| space per case | O(N) |

Counting every pair would spend O(N^2) time on the same decision.

The suffix pass makes each case linear in the array length.

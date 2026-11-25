# CPOD1 — Closest pairs in 1D V1 (SPOJ)

<https://www.spoj.com/problems/CPOD1/>

## Problem

Each test case gives n integers. Print the smallest distance |Ai - Aj| between two different elements.

| Item | Bound |
|---|---|
| Test cases | 1 ≤ t ≤ 10 |
| n | 2 ≤ n ≤ 100000 |
| Values | ±2 × 10^9 stated; a note warns some reach ±2 × 10^10 |
| Judge limit | 1000 ms, 1536 MB |
| Language | Nim (judge Nim 0.19.4) |

The sample case:

```
2
5
-2 -1 0 1 2
2
1 10
```

```
1
9
```

## Idea

Sort the array, then scan neighbors: the closest pair must sit next to each other in sorted order. A comparison sort with a closure comparator was too slow on the judge's Cube cluster, so the program sorts with an LSD radix sort using 12-bit digits. The pass count comes from the actual data range, so ordinary cases need only three or four passes.

## Why It Works

1. After sorting, any non-adjacent pair has a gap at least as large as some adjacent gap, so the minimum is adjacent.
2. Subtracting the minimum turns every value into a non-negative offset without changing differences.
3. Counting sort on one digit is stable, so feeding digits from least to most significant sorts the whole number.
4. Passes = ceil(bits(range) / 12); the range fits in 36 bits at ±2 × 10^10, so at most four passes ever run.
5. All values and differences fit in int64, so no overflow occurs.
6. The scan breaks early once a zero gap appears, since nothing can beat it.

| Term | Meaning |
|---|---|
| `nextSignedInt` | hand scanner that reads negative numbers |
| `radixSortAscending` | LSD radix sort with 12-bit digits |
| `minValue` / `maxValue` | data range used to size the passes |
| `count` | 4096-bucket histogram, reused per pass |
| `scratch` | second array for the stable scatter |
| `closestGap` | best adjacent difference |

A script-traced example from `gen.py`:

```
values -2 -1 0 1 2
sorted -2 -1 0 1 2
gaps   1  1  1  1
answer 1
```

The trace matches the first sample answer.

## Code

**Input and hand scanner.** This block loads stdin and reads signed integers by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt(data: string, position: var int): int64 =
  while position < data.len and data[position] != '-' and (data[position] < '0' or data[position] > '9'):
    position += 1
  var negative = false
  if position < data.len and data[position] == '-':
    negative = true
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  if negative:
    return -value
  return value
```

One readLine loop collects all input bytes.
The scanner handles the minus sign before building the number.

**Buffered output.** This block collects finished answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after reaching 128 KiB.
One final write emits any remaining bytes.

**Radix sort.** This block sorts one case in a few linear passes.

```nim
proc radixSortAscending(values: var seq[int64], count: var seq[int], scratch: var seq[int64]) =
  let n = values.len
  var minValue = values[0]
  var maxValue = values[0]
  for i in 1..<n:
    if values[i] < minValue: minValue = values[i]
    if values[i] > maxValue: maxValue = values[i]
  if minValue == maxValue: return
  for i in 0..<n: values[i] = values[i] - minValue
  var walk = cast[uint64](maxValue - minValue)
  var bits = 0
  while walk > 0'u64:
    bits += 1
    walk = walk shr 1
  let passes = (bits + 11) div 12
  let digitMask = 0xFFF'u64
  scratch.setLen n
  var shift = 0
  for pass in 0..<passes:
    for i in 0..4095: count[i] = 0
    for i in 0..<n:
      inc count[int((cast[uint64](values[i]) shr shift) and digitMask)]
    var total = 0
    for i in 0..4095:
      let c = count[i]
      count[i] = total
      total += c
    for i in 0..<n:
      let d = int((cast[uint64](values[i]) shr shift) and digitMask)
      scratch[count[d]] = values[i]
      inc count[d]
    swap(values, scratch)
    shift += 12
```

The min-max scan sizes the work: equal values return at once.
Each pass is two linear sweeps plus a 4096-entry prefix sum.
The swap leaves the sorted order in `values` after the last pass.

**Case loop.** This block reads each case, sorts, and finds the closest gap.

```nim
let caseCount = int(nextSignedInt(inputData, scanPos))
var values = newSeq[int64](0)
var scratchValues = newSeq[int64](0)
var count = newSeq[int](4096)
for caseIndex in 0..<caseCount:
  let elementCount = int(nextSignedInt(inputData, scanPos))
  values.setLen elementCount
  for i in 0..<elementCount:
    values[i] = nextSignedInt(inputData, scanPos)
  radixSortAscending(values, count, scratchValues)
  var closestGap = values[1] - values[0]
  for i in 1..<elementCount:
    let gap = values[i] - values[i - 1]
    if gap < closestGap:
      closestGap = gap
      if closestGap == 0: break
  appendOutput($closestGap & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The arrays are allocated once and reused across cases.
The gap scan stops as soon as it sees zero.

## Complexity

The cost splits into input, sorting, and the neighbor scan.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Radix sort | O(n · passes), passes ≤ 4 | O(n) scratch |
| Gap scan | O(n) per case | constant |

| Measure | Big O |
|---|---|
| Time | O(n) per case with a small constant |
| Space | O(n) |

Checking every pair costs O(n²), up to 5 × 10^9 comparisons; sorting keeps it linear.

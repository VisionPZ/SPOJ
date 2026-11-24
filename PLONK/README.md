## Problem

Each test case gives `n` friends at street crossroads with coordinates xi yi. Choose one friend's house as the meeting place so that the total walking distance of all friends is smallest. Print that minimum distance, one line per case.

| Quantity | Bound |
| --- | --- |
| Friends per case `n` | 1 to 10000 |
| Coordinates xi, yi | 0 to 100000 |
| Time limit | 6000 ms |
| Memory limit | 1536 MB |

The output is one number per case, so input parsing and sorting dominate the runtime.

## Idea

Walking along streets gives a Manhattan distance, which splits into an x part and a y part. Sort each coordinate and build prefix sums, then price every possible house in constant time. Scan the given houses once and keep the smallest combined price.

Cost per case: sorting takes O(n log n), and pricing plus scanning takes O(n).

## Why It Works

Walking from (1, 3) to (3, 5) takes 4 steps: 2 horizontal and 2 vertical. Summed over all friends, the total equals a term using only the meeting x plus a term using only the meeting y.

For a group of equal x values, let `l` be the first index and `j` the index after the last copy. The coordinate is `value`. The price is the following expression.

`value * l - prefixX[l] + (totalX - prefixX[j]) - value * (friendCount - j)`.

`prefixX[l]` is the sum of x values below the group, so the first pair counts the steps from friends on the left. `totalX - prefixX[j]` is the sum of x values above the group, so the last pair counts steps from friends on the right. Equal values share one price, so the group loop visits each distinct coordinate once. The same formula fills `costAtY`. For each house, `costAtX[coordX[i]] + costAtY[coordY[i]]` is its total, and `minTotal` holds the smallest one.

Prices for the sample friends.

| Friend | x cost | y cost | total |
| --- | --- | --- | --- |
| (1, 3) | 33 | 16 | 49 |
| (3, 2) | 23 | 19 | 42 |
| (3, 5) | 23 | 16 | 39 |
| (6, 9) | 22 | 32 | 54 |
| (10, 1) | 34 | 24 | 58 |
| (12, 4) | 44 | 15 | 59 |
| (5, 7) | 21 | 22 | 43 |

The smallest total is 39, which matches the sample output.

## Code

The input is read once into one buffer, then a hand scanner walks the buffer. No allocation happens while numbers are parsed.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value
```

The loop ends at end of input, and the scanner stops at each non-digit. The loop runs once per input line; parsing is O(total tokens).

Output is collected in one string and written in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes every `flushBlockBytes` bytes, never per line. This keeps write calls few on large outputs.

Each coordinate list is sorted, and prefix sums make later pricing constant time.

```nim
  var sortedX = coordX
  var sortedY = coordY
  sortedX.sort(compareInts)
  sortedY.sort(compareInts)

  var prefixX: seq[int64] = @[]
  var prefixY: seq[int64] = @[]
  prefixX.setLen(friendCount + 1)
  prefixY.setLen(friendCount + 1)
  for i in 0..<friendCount:
    prefixX[i + 1] = prefixX[i] + sortedX[i]
    prefixY[i + 1] = prefixY[i] + sortedY[i]
```

Both loops run `friendCount` times. `prefixX` has one extra cell so an empty prefix is zero. Sorting costs O(n log n) here.

Each group of equal x values gets one price, then the same happens for y.

```nim
  var l = 0
  while l < friendCount:
    var j = l + 1
    while j < friendCount and sortedX[j] == sortedX[l]:
      j += 1
    let value = sortedX[l]
    costAtX[value] = int64(value) * l - prefixX[l] + (totalX - prefixX[j]) - int64(value) * (friendCount - j)
    l = j
```

The outer loop stops at `friendCount`; `j` stops at the first different value. Grouping avoids pricing the same coordinate twice. The cost is O(n) per dimension.

Finally, each stored house price is checked and the minimum is appended.

```nim
  var minTotal = high(int64)
  for i in 0..<friendCount:
    let candidateTotal = costAtX[coordX[i]] + costAtY[coordY[i]]
    if candidateTotal < minTotal:
      minTotal = candidateTotal

  appendOutput($minTotal)
  outputBuffer.add '\n'
```

The scan visits every house once and adds one newline. `high(int64)` is a safe starting value because all distances fit in 64 bits.

## Complexity

Reading and scanning take O(total input tokens) time. Each case sorts two lists in O(n log n) time and O(n) space. Pricing, the final scan, and prefix sums take O(n) time. The two cost arrays occupy O(100001) int64 cells. Total time is O(t n log n). The naive approach sums distances from every house to every friend, which takes O(n²) per case.

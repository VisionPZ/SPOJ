# PLD — Palindromes (SPOJ)

<https://www.spoj.com/problems/PLD/>

## Problem

Count how many length-`k` substrings of a lowercase string read the same backwards. Two occurrences count separately whenever they start at different positions.

Input gives `k` on the first line and string `S` on the second line. Output one integer, the number of length-`k` palindromes.

| item | bound |
|---|---|
| palindrome length k | 2 to 30000 |
| string length | up to 30000 |
| test cases | one |
| judge limit | 100 ms, 1536 MB |

Both bounds allow a linear scan with no second string pass.

Sample input:

```
5
ababab
```

Sample output:

```
2
```

## Idea

Think of each palindrome as a fold in paper, where one center fixes every matching pair. Manacher's algorithm finds the longest palindrome radius at each center in one pass.

A length-`k` palindrome exists at a center exactly when that radius reaches `k/2`. Scanning all centers costs linear time. Rechecking each candidate substring would cost O(nk).

One Manacher pass answers the query for any `k`.

## Why It Works

1. An odd palindrome of length `2t+1` has one character at its center.
2. An even palindrome of length `2t` has its center between two characters.
3. `oddRadius[i]` counts matching character pairs around position `i`.
4. `evenRadius[i]` counts matching pairs around the gap before position `i`.
5. A center supports length `k` when its radius reaches half of `k`.

| term | meaning |
|---|---|
| `patternLength` | required palindrome length `k` |
| `oddRadius` | odd palindrome radius at each position |
| `evenRadius` | even palindrome radius at each gap |
| `palindromeCount` | number of centers long enough |

A worked trace follows for the sample word `ababab` with `k = 5`.

```
centre 2: radius 3 reaches 3, palindrome ababa
centre 3: radius 3 reaches 3, palindrome babab
count = 2
```

The trace matches the sample answer of two.

## Code

**Input reading.** The hand scanner reads `k`, then collects lowercase letters.

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < 'a' or data[pos] > 'z'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'a' and data[pos] <= 'z':
    word.add data[pos]
    pos += 1
  return word
```

The word reader skips newlines.
Only lowercase letters belong to the string.
One input buffer holds the whole file.

**Odd radii.** Each center expands only while characters match.

```nim
var oddRadius = newSeq[int](charCount)
var oddLeft = 0
var oddRight = -1
for centerIndex in 0 .. charCount - 1:
  var radius = 1
  if centerIndex <= oddRight:
    let mirrorIndex = oddLeft + oddRight - centerIndex
    let available = oddRight - centerIndex + 1
    radius = oddRadius[mirrorIndex]
    if radius > available:
      radius = available
  while centerIndex - radius >= 0 and centerIndex + radius < charCount and textChars[centerIndex - radius] == textChars[centerIndex + radius]:
    radius += 1
  oddRadius[centerIndex] = radius
  if centerIndex + radius - 1 > oddRight:
    oddLeft = centerIndex - radius + 1
    oddRight = centerIndex + radius - 1
```

Mirrored centers give a starting radius.
The rightmost reach bounds the mirror value.
Each position expands at most once overall.

**Even radii and counting.** Even centers sit between two letters.

```nim
var evenRadius = newSeq[int](charCount)
var evenLeft = 0
var evenRight = -1
for centerIndex in 0 .. charCount - 1:
  var radius = 0
  if centerIndex <= evenRight:
    let mirrorIndex = evenLeft + evenRight - centerIndex + 1
    let available = evenRight - centerIndex + 1
    radius = evenRadius[mirrorIndex]
    if radius > available:
      radius = available
  while centerIndex - radius - 1 >= 0 and centerIndex + radius < charCount and textChars[centerIndex - radius - 1] == textChars[centerIndex + radius]:
    radius += 1
  evenRadius[centerIndex] = radius
  if centerIndex + radius - 1 > evenRight:
    evenLeft = centerIndex - radius
    evenRight = centerIndex + radius - 1

var palindromeCount = 0
if (patternLength and 1) == 1:
  let needed = patternLength div 2 + 1
  for centerIndex in 0 .. charCount - 1:
    if oddRadius[centerIndex] >= needed:
      palindromeCount += 1
else:
  let needed = patternLength div 2
  for centerIndex in 0 .. charCount - 1:
    if evenRadius[centerIndex] >= needed:
      palindromeCount += 1

appendOutput($palindromeCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Odd lengths use odd centers, even lengths use even centers.
Each start position maps to one center, so counting centers counts occurrences.
The single result is flushed after the scan.

## Complexity

Manacher's two passes dominate the runtime.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | input string |
| radius scan | two linear passes | two radius arrays |
| output | one write | block buffer |

The mirror rule keeps total expansions linear.

| measure | Big O |
|---|---|
| time | O(n) |
| space | O(n) |

Rechecking every length-`k` window would cost O(nk) instead of O(n).

Manacher answers the single query in linear time, well inside the 100 ms limit.

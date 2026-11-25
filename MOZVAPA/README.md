# MOZVAPA — Valid Parentheses (SPOJ)

<https://www.spoj.com/problems/MOZVAPA/>

## Problem

For each query on a parentheses string, decide whether the substring between L and R can be reordered into a valid parentheses sequence. Only rearrangement inside that interval is allowed.

Input starts with test count t. Each case gives n, the string of n brackets, query count Q, then Q pairs L and R with 1-based inclusive ends. Print YES or NO on its own line for every query.

| item | bound |
|---|---|
| test cases t | 1 to 100 |
| string length n | 1 to 100000 |
| queries Q per case | 1 to 100000 |
| sum of all n | at most 500000 |
| judge limit | 1000 ms, 1536 MB |

The statement's example is a placeholder, so the sample below is a constructed case.

Sample input:

```
1
6
())(()
4
1 2
1 3
2 5
1 6
```

Sample output:

```
YES
NO
YES
YES
```

## Idea

Think of pairing every opening bracket with one closing bracket. A valid sequence needs exactly one partner of each kind, so equal counts are both necessary and enough. Count openings with a prefix array and answer each query with one subtraction. Rechecking the substring by sorting or permuting on every query costs far more and misses the bound.

Build one prefix count per position. Compare twice the openings against the interval length.

## Why It Works

1. A valid parentheses sequence has an equal number of openings and closings.
2. Any multiset with equal counts can be ordered as pairs, so equal counts are enough.
3. An odd interval length cannot split into equal counts.
4. The prefix array gives openings in positions L through R with one subtraction.
5. Twice that count equals the interval length exactly when the counts match.

| term | meaning |
|---|---|
| `bracketString` | the parentheses string for one case |
| `openPrefix` | number of openings before each position |
| `spanLength` | R minus L plus one |
| `openCount` | openings inside the queried interval |

For the sample string `())(()`, the substring between 1 and 5 is `())((` with 3 openings in 5 places, so the answer is NO.

| query | substring | length | openings | answer |
|---|---|---|---|---|
| 1 2 | `()` | 2 | 1 | YES |
| 1 3 | `()(` | 3 | 2 | NO |
| 2 5 | `)(()` | 4 | 2 | YES |
| 1 6 | `())(()` | 6 | 3 | YES |

The last column matches the sample output.

## Code

**Input and scanning.** The reader loads stdin and extracts each case's tokens.

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var word = ""
  while pos < data.len and data[pos] > ' ':
    word.add data[pos]
    pos += 1
  return word
```

The token reader keeps every bracket and skips the query numbers. Both scanners share one position index.

**Prefix counts and queries.** One pass builds the table, then each query costs constant time.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let bracketCount = nextInt(inputData, scanPos)
  let bracketString = nextToken(inputData, scanPos)
  var openPrefix = newSeq[int](bracketCount + 1)
  openPrefix[0] = 0
  for position in 0 .. bracketCount - 1:
    openPrefix[position + 1] = openPrefix[position]
    if bracketString[position] == '(':
      openPrefix[position + 1] += 1
  let queryCount = nextInt(inputData, scanPos)
  for queryIndex in 0 .. queryCount - 1:
    let leftEnd = nextInt(inputData, scanPos)
    let rightEnd = nextInt(inputData, scanPos)
    let spanLength = rightEnd - leftEnd + 1
    let openCount = openPrefix[rightEnd] - openPrefix[leftEnd - 1]
    if spanLength mod 2 == 0 and openCount * 2 == spanLength:
      appendOutput("YES\n")
    else:
      appendOutput("NO\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Positions are 1-based, so the prefix before L is at index L minus one. Multiplication avoids a division in the query check. Buffered writes handle a large answer stream.

## Complexity

The prefix pass runs once per case, then each query is constant work.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin | one input string |
| prefix build | one pass over n brackets | prefix array of n+1 integers |
| queries | two array reads per query | block buffer |

The query loop dominates when Q is large.

| measure | Big O |
|---|---|
| time | O(n + Q) per case |
| space | O(n) per case |

Permuting each substring would take factorial time in the interval length, while the prefix array settles each query in constant time. That subtraction sets the cost.

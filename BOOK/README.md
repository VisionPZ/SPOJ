# BOOK — Booklets (SPOJ)

<https://www.spoj.com/problems/BOOK/>

## Problem

Sort the booklets by page count, cut the sorted row into one block per school,
then report the page count of the first booklet handed to one chosen school.

Input starts with `t`, the number of cases. Each case gives the school count, the
queried school index starting at zero, the booklet count, then one page count per
booklet in list order. Spaces and line breaks between numbers are free. Output
one line per case with that page count.

Write `N` for the booklet count, `S` for the school count, and `K` for the
queried school index.

The bounds from the statement:

| Item | Bound |
|---|---|
| Cases `t` | at most 20 |
| Booklets `N` | fewer than 3000 |
| Page counts | distinct integers that fit in `int` |
| Judge limit | 5 s, 1536 MB |

The small booklet limit lets one flat array serve each case.

The sample case:

```
1
3
2
7
3 5 9 1 11 14 2
```

```
11
```

The last school gets the two largest booklets, and list position 4 holds 11.

## Idea

Lay the booklets out from fewest pages to most, then cut the row into school sized
pieces. It works like dealing a sorted deck into fixed hands, then checking one hand.

The program sorts booklet pairs by page count with insertion sort. It computes the
queried school's slice from the quotient and remainder of `N` over `S`. Then it
scans that slice for the smallest `listIndex`, since each school hands out its
booklets in original list order.

Sorting costs about N squared divided by four comparisons for shuffled pages. The
slice scan costs at most one school's group size. A naive deal repeats a minimum
search for every booklet and builds a group list per school, which adds work at
every step.

Sort once, then read one slice.

## Why It Works

Four facts fix the answer without simulating the whole deal.

1. The page rule puts schools in sorted order. When school i comes before school
   j, every booklet in i has no more pages than every booklet in j. Distinct page
   counts make the groups consecutive blocks of the sorted list.
2. Division fixes the block sizes. `lowerCount` is N divided by S, and
   `extraCount` is the remainder. Schools before `extraCount` get one more
   booklet, and Bob visits those schools first.
3. `groupStart` points at the queried school's first sorted slot. When the query
   is at least `extraCount`, the start skips all larger blocks, then adds one
   smaller block for each earlier school.
4. Within one block, the first booklet handed over has the smallest `listIndex`.
   That booklet has the earliest position in the original list.

The terms below describe one case:

| Term | Meaning |
|---|---|
| `lowerCount` | N divided by S, the smaller group size |
| `extraCount` | N modulo S, the number of schools with a larger group |
| `upperCount` | `lowerCount` plus one when `extraCount` is positive |
| `groupStart` | first sorted slot of the queried school |
| `earliestIndex` | smallest original list position in that slot range |

These five values locate the answer with no per-school allocation.

A script traces the sample case:

```
case: S=3 K=2 N=7
sorted (pages,listIndex): (1,3) (2,6) (3,0) (5,1) (9,2) (11,4) (14,5)
lower=2 extra=1 upper=3
school0 sorted positions [0,3) listIndexes 3 6 0
school1 sorted positions [3,5) listIndexes 1 2
school2 sorted positions [5,7) listIndexes 4 5
school2 earliest listIndex=4 pages=11
answer 11
```

School 2 owns sorted slots 5 and 6; list index 4 wins and its page count is 11.

## Code

**Setup.** Fixed constants and the pair that carries one booklet.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

type Booklet = tuple[pages: int, listIndex: int]
```

The digit base turns a byte into a value. The flush threshold limits memory.
Each pair keeps the page count and the original list position together.

**Token reader.** Digits are scanned by index, with no substring allocation.

```nim
proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The first loop skips free whitespace. The second loop builds the value digit by
digit. The parameter `pos` keeps its place across calls.

**Sort.** Booklets are ordered by pages, with insertion sort.

```nim
proc sortBooklets(booklets: var seq[Booklet]) =
  for outerIndex in 1 ..< booklets.len:
    let current = booklets[outerIndex]
    var innerIndex = outerIndex - 1
    while innerIndex >= 0 and booklets[innerIndex].pages > current.pages:
      booklets[innerIndex + 1] = booklets[innerIndex]
      innerIndex -= 1
    booklets[innerIndex + 1] = current
```

The outer loop starts at one and ends before `booklets.len`. The inner loop shifts
larger pages right. Every pair keeps its original list position while it moves.

**Driver.** One read of stdin, one slice per case, buffered writes.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

for _ in 0..<caseCount:
  let schoolCount = nextInt(inputData, scanPos)
  let querySchool = nextInt(inputData, scanPos)
  let bookletCount = nextInt(inputData, scanPos)
  var booklets: seq[Booklet]
  booklets.setLen(bookletCount)
  for listIndex in 0..<bookletCount:
    booklets[listIndex] = (pages: nextInt(inputData, scanPos), listIndex: listIndex)
  sortBooklets(booklets)
  let lowerCount = bookletCount div schoolCount
  let extraCount = bookletCount mod schoolCount
  let upperCount = lowerCount + (if extraCount > 0: 1 else: 0)
  let groupStart = if querySchool < extraCount:
    querySchool * upperCount
  else:
    extraCount * upperCount + (querySchool - extraCount) * lowerCount
  let groupSize = if querySchool < extraCount: upperCount else: lowerCount
  var earliestIndex = bookletCount
  var answer = 0
  for groupPos in groupStart ..< groupStart + groupSize:
    if booklets[groupPos].listIndex < earliestIndex:
      earliestIndex = booklets[groupPos].listIndex
      answer = booklets[groupPos].pages
  outputBuffer.add $answer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

`inputData` holds the entire stream, so odd spacing cannot desync the reader.
`groupStart` and `groupSize` mark one school's slot range. `outputBuffer` flushes
at `flushBlockBytes`, then once more for the tail.

## Complexity

One case reads the stream, sorts once, scans one slice, and appends one line.

| Phase | Time | Space |
|---|---|---|
| Input read | one line pass, then one digit pass | input bytes |
| Sort | about N squared divided by four comparisons | N booklet pairs |
| Slice scan | at most upperCount positions | constant |
| Output | one write per flush block | flushBlockBytes bytes |

The sort dominates; each other phase is linear in its own input.

| Measure | Big O |
|---|---|
| Time | O(t * N^2) with insertion sort |
| Space | O(N) for one case, plus the input buffer |

These bounds keep all 20 legal cases far below the judge limit.

A repeated minimum search also costs O(N^2), but it builds a group per school.
Sorting once and scanning one slice does less bookkeeping and stays smaller.

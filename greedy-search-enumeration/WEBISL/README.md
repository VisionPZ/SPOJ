# WEBISL — Web islands (SPOJ)

<https://www.spoj.com/problems/WEBISL/>

## Problem

Group web pages into the largest sets where every page in a set can reach every other page by following links. Print the smallest page number in each group, once for each page.

Input starts with the page count and the link count. Each later line holds a source page and a target page. Pages are numbered from zero. Output one line per page with the smallest index in that page's group.

| item | bound |
|---|---|
| pages | up to about 97000 from judge probing |
| links | bounded by available memory |
| page numbering | 0 to page count minus one |
| judge limit | 1000 ms, 1536 MB |

Sparse graphs make a linear adjacency layout the right fit.

Sample input:

```
3 3
0 1
1 0
1 2
```

Sample output:

```
0
0
2
```

Pages zero and one form one group; page two forms its own group.

## Idea

Think of one-way streets and ask which blocks let you drive from any house to any other house in the block. Kosaraju's algorithm finds those blocks with two depth-first passes, one on the links and one on the reversed links. Each pass touches every page and link once, so the work stays linear. Testing every pair of pages by a separate search would cost far more on large inputs. Finish the ordering pass first, then collect groups in that order.

## Why It Works

1. Two pages belong together exactly when each can reach the other.
2. A depth-first pass on the forward links records pages after all their descendants.
3. Processing those finish times in reverse sends each reversed pass to one whole group.
4. The reversed links of a group keep the search inside that group.
5. Taking the minimum page number in a group gives the required component ID.
6. An explicit stack replaces recursion, so long chains cannot overflow the call stack.

| term | meaning |
|---|---|
| `forwardHead` | first outgoing link of each page |
| `reverseHead` | first incoming link of each page |
| `finishOrder` | pages sorted by depth-first finish time |
| `componentId` | smallest page number in the group of each page |
| `stackPages` | explicit stack of pages in the first pass |
| `componentPages` | collected members of one group |

Edge arrays plus head arrays store both directions without per-page lists.

A trace of the sample shows the two passes:

```
finish order 2 1 0
group members 0 1 smallest 0
group members 2 smallest 2
answer 0 0 2
```

The reverse pass visits pages zero and one together, then page two alone.

## Code

**Input and edge storage.** The reader builds forward and reverse adjacency with head and next arrays.

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

The hand scanner ignores all spacing between integers.
Both directions use the same pair of edge arrays.
Array storage avoids many small dynamic lists.

```nim
let pageCount = nextInt(inputData, scanPos)
let linkCount = nextInt(inputData, scanPos)
var forwardHead = newSeq[int](pageCount)
var reverseHead = newSeq[int](pageCount)
for pageIndex in 0 .. pageCount - 1:
  forwardHead[pageIndex] = -1
  reverseHead[pageIndex] = -1
var forwardTarget = newSeq[int](linkCount)
var forwardNext = newSeq[int](linkCount)
var reverseSource = newSeq[int](linkCount)
var reverseNext = newSeq[int](linkCount)
for linkIndex in 0 .. linkCount - 1:
  let sourcePage = nextInt(inputData, scanPos)
  let targetPage = nextInt(inputData, scanPos)
  forwardTarget[linkIndex] = targetPage
  forwardNext[linkIndex] = forwardHead[sourcePage]
  forwardHead[sourcePage] = linkIndex
  reverseSource[linkIndex] = sourcePage
  reverseNext[linkIndex] = reverseHead[targetPage]
  reverseHead[targetPage] = linkIndex
```

Each link is inserted at the head of two lists.
Minus one marks the end of a list.
Reading all links first keeps both passes cache friendly.

**First pass.** An explicit stack produces the finish order without recursion.

```nim
var pageVisited = newSeq[bool](pageCount)
var finishOrder = newSeq[int](pageCount)
finishOrder.setLen 0
var stackPages = newSeq[int](pageCount)
var stackEdges = newSeq[int](pageCount)
for startPage in 0 .. pageCount - 1:
  if pageVisited[startPage]:
    continue
  var stackSize = 0
  pageVisited[startPage] = true
  stackPages[0] = startPage
  stackEdges[0] = forwardHead[startPage]
  stackSize = 1
  while stackSize > 0:
    let topPosition = stackSize - 1
    let currentEdge = stackEdges[topPosition]
    if currentEdge != -1:
      stackEdges[topPosition] = forwardNext[currentEdge]
      let nextPage = forwardTarget[currentEdge]
      if not pageVisited[nextPage]:
        pageVisited[nextPage] = true
        stackPages[stackSize] = nextPage
        stackEdges[stackSize] = forwardHead[nextPage]
        stackSize += 1
    else:
      finishOrder.add stackPages[topPosition]
      stackSize -= 1
```

Each stack slot keeps its next edge to try.
A page is appended once all its links are exhausted.
The stack never grows past the page count.

**Second pass and output.** Reversed traversal collects groups and writes one ID per page.

```nim
var componentId = newSeq[int](pageCount)
for pageIndex in 0 .. pageCount - 1:
  componentId[pageIndex] = -1
var componentPages = newSeq[int](pageCount)
var finishIndex = finishOrder.len - 1
while finishIndex >= 0:
  let startPage = finishOrder[finishIndex]
  finishIndex -= 1
  if componentId[startPage] != -1:
    continue
  var componentSize = 0
  componentPages[0] = startPage
  componentSize = 1
  componentId[startPage] = -2
  var queueHead = 0
  while queueHead < componentSize:
    let currentPage = componentPages[queueHead]
    queueHead += 1
    var currentEdge = reverseHead[currentPage]
    while currentEdge != -1:
      let nextPage = reverseSource[currentEdge]
      if componentId[nextPage] == -1:
        componentId[nextPage] = -2
        componentPages[componentSize] = nextPage
        componentSize += 1
      currentEdge = reverseNext[currentEdge]
  var smallestPage = startPage
  for memberIndex in 0 .. componentSize - 1:
    if componentPages[memberIndex] < smallestPage:
      smallestPage = componentPages[memberIndex]
  for memberIndex in 0 .. componentSize - 1:
    componentId[componentPages[memberIndex]] = smallestPage

for pageIndex in 0 .. pageCount - 1:
  appendOutput($componentId[pageIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The value minus two marks a page claimed by the current group.
The smallest member becomes the final ID for every member.
Buffered writes emit one line per page.

## Complexity

Both depth-first passes scan each page and link a constant number of times.

| phase | time | space |
|---|---|---|
| input read | one pass over link pairs | one input string |
| forward pass | one visit per page and link | two stacks of page count |
| reverse pass | one visit per page and link | group member array |
| output | one buffered write per block | one output string |

The two passes together stay proportional to the graph size.

| measure | Big O |
|---|---|
| time | O(pages + links) |
| space | O(pages + links) |

Testing reachability for every pair would cost far more than two linear passes.
Use head and next arrays for both directions and finish with the smallest member ID.

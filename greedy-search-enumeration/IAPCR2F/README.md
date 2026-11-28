# IAPCR2F — Summer Trip (SPOJ)

<https://www.spoj.com/problems/IAPCR2F/>

## Problem

Students form groups through mutual acquaintances. Each student carries a fixed amount of money. Report the number of groups and each group's total money, sorted from smallest to largest.

Input starts with the test count. Each test gives the student count and relation count, then one line of money amounts, then one line per relation with two student numbers. Output `Case X: K` on its own line, followed by the K sorted group totals on the next line.

| item | bound |
|---|---|
| test cases | 1 to 50 |
| students per case | 1 to 1000 |
| relations per case | 0 to N(N-1)/2 |
| money per student | 1 to 100 |
| judge limit | 1000 ms, 1536 MB |

The student count drives the design. Money totals stay below 100000 and fit in a plain integer.

The exact sample input is:

    1
    5 3
    5 7 4 6 8
    1 2
    1 3
    4 5

The exact sample output is:

    Case 1: 2
    14 16

## Idea

Treat acquaintances as mergeable piles of money, like combining stacks of coins into boxes. A disjoint-set union merges two piles in almost constant time. Each merge adds one budget into another, and no edge is revisited. A plain graph traversal per query would repeat work on large connected parts.

The takeaway is to merge once, then sort only the finished group totals.

## Why It Works

1. Knowing someone is symmetric, so each relation joins two groups into one.
2. A union by size keeps each tree shallow, which makes finds fast.
3. Each root stores the running budget of its whole group.
4. Roots after all unions are exactly the connected components.
5. Sorting their budgets gives the required ascending output.

| term | meaning |
|---|---|
| `parentNode` | parent pointer of each student in the forest |
| `componentSize` | number of students under a root |
| `componentBudgets` | money total stored at each root |
| `groupBudgets` | totals of the final groups, sorted |

The table shows that only root entries carry group values.

A script trace of the sample merges follows:

    link 1-2: budget 12 at root 1
    link 1-3: budget 16 at root 1
    link 4-5: budget 14 at root 4
    roots hold 16 and 14, sorted to 14 16

The trace matches the sample output and confirms the merge rule.

## Code

**Input and hand scanner.** The reader loads all lines and parses positive integers.

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

One call reads a whole test file into one string.
The scanner skips spaces and line breaks between numbers.
No sign branch is needed because every input value is positive.

**Buffered output.** One string holds the answer lines and flushes in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes only after 131072 bytes fill.
The final flush happens after all cases finish.
Per number writes are avoided, which keeps output cheap.

**Root search.** Path compression shortens each tree during a find.

```nim
proc findRoot(parentNode: var seq[int], node: int): int =
  var root = node
  while parentNode[root] != root:
    root = parentNode[root]
  var walker = node
  while parentNode[walker] != root:
    let ancestor = parentNode[walker]
    parentNode[walker] = root
    walker = ancestor
  return root
```

The first loop reaches the root.
The second loop rewrites every visited pointer to that root.
No recursion is used, so deep trees cannot overflow the stack.

**Merge and report.** Unions by size build the groups, then insertion sort orders totals.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let studentCount = nextInt(inputData, scanPos)
  let relationCount = nextInt(inputData, scanPos)
  var parentNode = newSeq[int](studentCount)
  var componentSize = newSeq[int](studentCount)
  var componentBudgets = newSeq[int](studentCount)
  for studentIndex in 0 .. studentCount - 1:
    parentNode[studentIndex] = studentIndex
    componentSize[studentIndex] = 1
    componentBudgets[studentIndex] = nextInt(inputData, scanPos)
  for relationIndex in 0 .. relationCount - 1:
    let firstStudent = nextInt(inputData, scanPos) - 1
    let secondStudent = nextInt(inputData, scanPos) - 1
    let firstRoot = findRoot(parentNode, firstStudent)
    let secondRoot = findRoot(parentNode, secondStudent)
    if firstRoot != secondRoot:
      if componentSize[firstRoot] < componentSize[secondRoot]:
        parentNode[firstRoot] = secondRoot
        componentSize[secondRoot] += componentSize[firstRoot]
        componentBudgets[secondRoot] += componentBudgets[firstRoot]
      else:
        parentNode[secondRoot] = firstRoot
        componentSize[firstRoot] += componentSize[secondRoot]
        componentBudgets[firstRoot] += componentBudgets[secondRoot]
  var groupBudgets: seq[int] = @[]
  for studentIndex in 0 .. studentCount - 1:
    if parentNode[studentIndex] == studentIndex:
      groupBudgets.add componentBudgets[studentIndex]
  let groupCount = groupBudgets.len
  for sortIndex in 1 .. groupCount - 1:
    let keyBudget = groupBudgets[sortIndex]
    var shiftIndex = sortIndex - 1
    while shiftIndex >= 0 and groupBudgets[shiftIndex] > keyBudget:
      groupBudgets[shiftIndex + 1] = groupBudgets[shiftIndex]
      shiftIndex -= 1
    groupBudgets[shiftIndex + 1] = keyBudget
  let caseNumber = caseIndex + 1
  appendOutput("Case " & $caseNumber & ": " & $groupCount & "\n")
  for budgetIndex in 0 .. groupCount - 1:
    if budgetIndex > 0:
      appendOutput(" ")
    appendOutput($groupBudgets[budgetIndex])
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The smaller root joins the larger one on every merge.
Only root positions contribute to the final list.
Insertion sort handles at most 1000 totals per case.
The case number and budget line are written through one buffer.

## Complexity

Union and find work dominates the run.

| phase | time | space |
|---|---|---|
| input read | one pass over all numbers | one input string |
| merges | nearly one operation per relation | three arrays of N |
| sort | quadratic in the group count | one array of totals |
| output | one write per full block | block buffer |

The input scan and the merges are linear in practice.

| measure | Big O |
|---|---|
| time | O(N + M + G^2) per case |
| space | O(N) |

G is the group count, at most N.
A graph traversal for every pair would cost far more than one merge per relation.
The takeaway is that union by size with compression keeps the whole case fast.

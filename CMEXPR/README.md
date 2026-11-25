# CMEXPR — Complicated Expressions (SPOJ)

<https://www.spoj.com/problems/CMEXPR/>

## Problem

An accountant wants shorter arithmetic notes. Parentheses that do not change the meaning only add clutter, so the accountant removes them.

Input: one integer for the expression count, then one expression per line. Each expression uses lowercase variables, the operators `+ - * /`, and parentheses.

Output: one expression per line, with every removable parenthesis pair deleted.

The statement and judge give these bounds:

| Item | Bound |
| --- | --- |
| Expressions | about 10000 |
| Line length | at most 250 characters |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The largest legal input holds about 2.5 MB of expression text.

The sample input and output:

```
8
(a+(b*c))
((a+b)*c)
(a*(b*c))
(a*(b/c)*d)
((a/(b/c))/d)
((x))
(a+b)-(c-d)-(e/f)
(a+b)+(c-d)-(e+f)
```

```
a+b*c
(a+b)*c
a*b*c
a*b/c*d
a/(b/c)/d
x
a+b-(c-d)-e/f
a+b+c-d-(e+f)
```

## Idea

Unpack each expression like nested boxes. Every box becomes a node in a binary tree, and the printer wraps a child only when the tree order demands it.

The program parses with two stacks, one for operands and one for operators. A priority table then decides whether a child needs parentheses on the left or on the right.

Parsing and printing both visit each character or node once, so one expression costs O(L) time and O(L) space. Rewriting the line by repeatedly removing one pair would rescan the whole line each time.

The tree makes each parent-child decision local.

## Why It Works

Two properties decide every parenthesis pair.

1. Multiplication and division bind tighter than addition and subtraction, so their priority is 2 against 1.
2. A variable has priority 99, so no operator can require parentheses around it.
3. Operators of equal priority group from the left, so a left child keeps its order without parentheses.
4. A right child under `-` or `/` with equal priority keeps its parentheses, because regrouping changes its meaning.

The printer uses one threshold table:

| Child position | `+` | `-` | `*` | `/` |
| --- | --- | --- | --- | --- |
| Left | 1 | 1 | 2 | 2 |
| Right | 1 | 2 | 2 | 3 |

The right thresholds for `-` and `/` exceed the child priority by one. A right child with equal priority therefore stays wrapped.

A script prints the sample expressions after the tree pass:

| Input | Printed output |
| --- | --- |
| `(a+(b*c))` | `a+b*c` |
| `((a+b)*c)` | `(a+b)*c` |
| `a-(b-c)` | `a-(b-c)` |
| `a+(b-c)` | `a+b-c` |
| `a/(b/c)` | `a/(b/c)` |
| `(a+b)+(c-d)-(e+f)` | `a+b+c-d-(e+f)` |

In the last row, the `-` parent keeps `(e+f)` wrapped. The `+` parent before it drops the parentheses around `(c-d)`.

## Code

**Storage.** Fixed arrays hold the tree nodes and both stacks for one 250-character line.

```nim
const
  flushBlockBytes = 1 shl 18
  firstDigitValue = 48
  maxNodeCount = 512

var
  inputData = ""
  i = 0
  outputBuffer = ""
  nodeOp: array[0 .. maxNodeCount - 1, char]
  nodeLeft: array[0 .. maxNodeCount - 1, int]
  nodeRight: array[0 .. maxNodeCount - 1, int]
  nodeIsLeaf: array[0 .. maxNodeCount - 1, bool]
  valueStack: array[0 .. maxNodeCount - 1, int]
  operatorStack: array[0 .. maxNodeCount - 1, char]
  nodeCount = 0
  valueCount = 0
  operatorCount = 0
```

The 512 slots cover the 250-character limit. All buffers are allocated once. Setup costs constant work.

**Input helpers.** One scanner reads the count, and another reads one whole expression token.

```nim
proc nextInt(): int =
  while i < inputData.len and (inputData[i] < '0' or inputData[i] > '9'):
    inc i
  result = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    result = result * 10 + (int(inputData[i]) - firstDigitValue)
    inc i

proc readExpressionToken(token: var string) =
  token.setLen 0
  while i < inputData.len and inputData[i] <= ' ':
    inc i
  while i < inputData.len and inputData[i] > ' ':
    token.add inputData[i]
    inc i
```

`nextInt` skips whitespace and stops at the first non-digit. `readExpressionToken` stops at whitespace, so a newline ends an expression. Both scans advance the index once per character.

**Precedence and node creation.** Applying an operator pops two operands and pushes one tree node.

```nim
proc operatorPrecedence(op: char): int =
  if op == '*' or op == '/':
    result = 2
  else:
    result = 1

proc applyOperator() =
  dec valueCount
  let j = valueStack[valueCount]
  dec valueCount
  let i = valueStack[valueCount]
  dec operatorCount
  nodeOp[nodeCount] = operatorStack[operatorCount]
  nodeIsLeaf[nodeCount] = false
  nodeLeft[nodeCount] = i
  nodeRight[nodeCount] = j
  valueStack[valueCount] = nodeCount
  inc valueCount
  inc nodeCount
```

Both stacks hold at most L entries. Each operator is applied once, so the total cost is O(L).

**Tree build.** A left-to-right scan turns the token into nodes using the two stacks.

```nim
proc buildTree(token: string): int =
  nodeCount = 0
  valueCount = 0
  operatorCount = 0
  for currentChar in token:
    if currentChar == '(':
      operatorStack[operatorCount] = currentChar
      inc operatorCount
    elif currentChar == ')':
      while operatorStack[operatorCount - 1] != '(':
        applyOperator()
      dec operatorCount
    elif currentChar == '+' or currentChar == '-' or currentChar == '*' or currentChar == '/':
      while operatorCount > 0 and operatorStack[operatorCount - 1] != '(' and
            operatorPrecedence(operatorStack[operatorCount - 1]) >= operatorPrecedence(currentChar):
        applyOperator()
      operatorStack[operatorCount] = currentChar
      inc operatorCount
    else:
      nodeOp[nodeCount] = currentChar
      nodeIsLeaf[nodeCount] = true
      valueStack[valueCount] = nodeCount
      inc valueCount
      inc nodeCount
  while operatorCount > 0:
    applyOperator()
  result = valueStack[0]
```

The loop runs once per character, so L bounds it. A `(` opens a context and a `)` closes it. Equal-priority operators are applied at once, which gives left grouping.

**Printer.** A recursive walk emits parentheses only when the threshold table requires them.

```nim
proc emitNode(node: int, parentOp: char, side: int) =
  var needParens = false
  if side != 0 and not nodeIsLeaf[node]:
    let nodePrec = operatorPrecedence(nodeOp[node])
    let parentPrec = operatorPrecedence(parentOp)
    if nodePrec < parentPrec:
      needParens = true
    elif nodePrec == parentPrec and side == 2 and (parentOp == '-' or parentOp == '/'):
      needParens = true
  if needParens:
    outputBuffer.add '('
  if nodeIsLeaf[node]:
    outputBuffer.add nodeOp[node]
  else:
    emitNode(nodeLeft[node], nodeOp[node], 1)
    outputBuffer.add nodeOp[node]
    emitNode(nodeRight[node], nodeOp[node], 2)
  if needParens:
    outputBuffer.add ')'
```

The recursion visits each node once. Side 1 marks a left child and side 2 marks a right child. This test is the only place where parentheses are added.

**Driver.** The program reads the whole stream once and flushes output in blocks.

```nim
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

let expressionCount = nextInt()
var expressionToken = ""
for j in 0 .. expressionCount - 1:
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  readExpressionToken(expressionToken)
  let expressionRoot = buildTree(expressionToken)
  emitNode(expressionRoot, ' ', 0)
  outputBuffer.add '\n'
stdout.write outputBuffer
```

The expression loop runs once per line. The output buffer flushes at 256 KiB, so a large run costs few writes. The final write emits the short tail.

## Complexity

Building a tree scans L characters, and printing walks L nodes.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Tree build | O(L) per expression | O(L) nodes and stacks |
| Print | O(L) per expression | O(L) recursion |
| Output | one write per 256 KiB block | 256 KiB |
| Total | O(T × L) | O(T × L + L) working |

At the 250-character limit, one expression holds at most 250 nodes.

The asymptotic bounds are as follows:

| Measure | Big O |
| --- | --- |
| Time | O(T × L) for T expressions |
| Space | O(L) working space |

Removing one parenthesis pair at a time would rescan the line for each pair.

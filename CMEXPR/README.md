## Problem

Read T expressions, one per line. Each expression uses lowercase variables, the operators + - * /, and parentheses. Remove every parenthesis pair that leaves the expression semantically unchanged. Print the resulting expression for each line.

The input obeys these limits.

| Item | Value |
| --- | --- |
| Expressions | about 10000 |
| Line length | at most 250 characters |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The largest legal input holds about 2.5 MB of expression text.

## Idea

Parse each line into a binary expression tree with two stacks. Print the tree in order and wrap a child in parentheses only when a priority table says so. The left-child table and the right-child table encode the statement's associativity rules.

Each expression costs O(L) time and O(L) space, where L is its length.

## Why It Works

Multiplication and division have priority 2. Addition and subtraction have priority 1. A variable has priority 99, so it never needs parentheses. A child needs parentheses when its priority falls below a threshold.

| Child position | + | - | * | / |
| --- | --- | --- | --- | --- |
| Left | 1 | 1 | 2 | 2 |
| Right | 1 | 2 | 2 | 3 |

The right thresholds for '-' and '/' exceed the child priority by one. A right child with equal priority therefore keeps its parentheses. A left child with equal priority never does, because operators group from the left.

The statement allows associativity of addition and multiplication. It also allows + with - and * with / when the second operator is - or /. No other rearrangement is legal, so a right child under '-' or '/' must stay wrapped.

The following lines apply the rule.

| Input | Printed output |
| --- | --- |
| (a+(b*c)) | a+b*c |
| ((a+b)*c) | (a+b)*c |
| a-(b-c) | a-(b-c) |
| a+(b-c) | a+b-c |
| a/(b/c) | a/(b/c) |
| (a+b)+(c-d)-(e+f) | a+b+c-d-(e+f) |

In the last row, the '-' parent keeps (e+f) wrapped. The '+' parent before it drops the parentheses around (c-d).

## Code

```
const
  flushBlockBytes = 1 shl 18
  firstDigitValue = 48
  maxNodeCount = 512

var
  inputData = ""
  scanPos = 0
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

The arrays hold 512 nodes, which covers the 250-character limit. The buffers and both stacks are allocated once. Setup costs O(1).

```
proc nextInt(): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    inc scanPos
  result = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    result = result * 10 + (int(inputData[scanPos]) - firstDigitValue)
    inc scanPos

proc readExpressionToken(token: var string) =
  token.setLen 0
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    inc scanPos
  while scanPos < inputData.len and inputData[scanPos] > ' ':
    token.add inputData[scanPos]
    inc scanPos
```

nextInt skips whitespace and stops at the first non-digit. readExpressionToken stops at whitespace, so a newline ends an expression. Both scans advance scanPos once per character and cost O(L).

```
proc operatorPrecedence(op: char): int =
  if op == '*' or op == '/':
    result = 2
  else:
    result = 1

proc applyOperator() =
  dec valueCount
  let rightIndex = valueStack[valueCount]
  dec valueCount
  let leftIndex = valueStack[valueCount]
  dec operatorCount
  nodeOp[nodeCount] = operatorStack[operatorCount]
  nodeIsLeaf[nodeCount] = false
  nodeLeft[nodeCount] = leftIndex
  nodeRight[nodeCount] = rightIndex
  valueStack[valueCount] = nodeCount
  inc valueCount
  inc nodeCount
```

applyOperator pops two operands and one operator, then pushes the new node. Both stacks hold at most L entries. Each operator is applied once, so the total cost is O(L).

```
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

The main loop runs once per input character, so L bounds it. A '(' opens a context and ')' closes it. Operators of equal priority are applied at once, which gives left associativity.

```
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

The recursion visits each node once. side 1 marks a left child and side 2 marks a right child. The threshold test is the only place where parentheses are added.

```
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

let expressionCount = nextInt()
var expressionToken = ""
for expressionIndex in 0 .. expressionCount - 1:
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  readExpressionToken(expressionToken)
  let expressionRoot = buildTree(expressionToken)
  emitNode(expressionRoot, ' ', 0)
  outputBuffer.add '\n'
stdout.write outputBuffer
```

The expression loop runs T times. The input is read once into one string. The output buffer flushes in 256 KiB blocks, so large output costs few writes.

## Complexity

Building a tree scans L characters and creates at most L nodes. Printing walks each node once. The whole run costs O(T * L) time.

Input storage uses O(T * L) bytes. The node arrays and both stacks use O(L) space per expression. A direct rewrite that removes one pair of parentheses at a time would rescan the line for every pair.

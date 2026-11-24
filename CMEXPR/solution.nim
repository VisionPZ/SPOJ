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

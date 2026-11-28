{.push checks: off.}

const firstDigitValue = 48
const largeSentinel = 1000000000
const flushBlockBytes = 1 shl 18

proc nextInt(inputData: string, i: var int): int =
  let inputLength = inputData.len
  while i < inputLength and (inputData[i] < '0' or inputData[i] > '9'):
    i += 1
  var numberValue = 0
  while i < inputLength and inputData[i] >= '0' and inputData[i] <= '9':
    numberValue = numberValue * 10 + (int(inputData[i]) - firstDigitValue)
    i += 1
  return numberValue

proc readStreamBytes(): string =
  var res = ""
  var chunk = newString(1 shl 16)
  while true:
    let got = readBuffer(stdin, addr chunk[0], chunk.len)
    if got <= 0:
      break
    let oldLen = res.len
    res.setLen(oldLen + got)
    copyMem(addr res[oldLen], addr chunk[0], got)
  return res

let inputData = readStreamBytes()
var i = 0
let caseCount = nextInt(inputData, i)
var outputBuffer = ""

for j in 0 ..< caseCount:
  let inputCount = nextInt(inputData, i)
  let sorterCount = nextInt(inputData, i)
  var baseSize = 1
  while baseSize <= inputCount:
    baseSize = baseSize shl 1
  var tree = newSeq[int](baseSize shl 1)
  for k in 0 ..< tree.len:
    tree[k] = largeSentinel
  tree[baseSize + 1] = 0
  var l = baseSize + 1
  l = l shr 1
  while l >= 1:
    tree[l] = 0
    l = l shr 1
  var bestCosts = newSeq[int](inputCount + 1)
  for k in 0 .. inputCount:
    bestCosts[k] = largeSentinel
  bestCosts[1] = 0
  for l in 0 ..< sorterCount:
    let leftEdge = nextInt(inputData, i)
    let rightEdge = nextInt(inputData, i)
    var lowNode = leftEdge + baseSize
    var highNode = rightEdge + baseSize
    var bestEarlier = largeSentinel
    while lowNode <= highNode:
      if (lowNode and 1) != 0:
        if tree[lowNode] < bestEarlier:
          bestEarlier = tree[lowNode]
        lowNode += 1
      if (highNode and 1) == 0:
        if tree[highNode] < bestEarlier:
          bestEarlier = tree[highNode]
        highNode -= 1
      lowNode = lowNode shr 1
      highNode = highNode shr 1
    let trialCost = bestEarlier + 1
    if trialCost < bestCosts[rightEdge]:
      bestCosts[rightEdge] = trialCost
      var k = rightEdge + baseSize
      tree[k] = trialCost
      k = k shr 1
      while k >= 1:
        let leftChild = tree[k shl 1]
        let rightChild = tree[(k shl 1) + 1]
        var childMinimum = leftChild
        if rightChild < childMinimum:
          childMinimum = rightChild
        if childMinimum == tree[k]:
          break
        tree[k] = childMinimum
        k = k shr 1
  outputBuffer.add $bestCosts[inputCount]
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer

{.pop.}

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

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

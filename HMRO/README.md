# HMRO — Help the Military Recruitment Office! (SPOJ)

<https://www.spoj.com/problems/HMRO/>

## Problem

The input lists people by PESEL code with a recruitment office, then closed
offices each redirected to another office. For every PESEL in the final query
list, print that PESEL and the office reached by following the redirections.

Each test case lists up to 100 000 boys with their PESEL code and their old
recruitment office code, then up to 100 000 redirections `old office new office`,
then up to 100 000 PESEL codes of the boys who are recruited. For every
recruited boy print the PESEL and the office code it reaches after following the
redirections. Test cases are separated by an empty line in the output.

## Idea

Every office code is given a slot in a table of all office codes of the test case,
and each redirection `old new` writes `parent[old] = new`. Following a chain of
closures then becomes a `find` on that parent array, with path compression, so a
long chain is walked once and later queries jump straight to the final office.
Boys are found by sorting the PESEL records and binary searching them.

## Why It Works

PESEL codes are 11 digits, so they overflow a 32 bit integer; keeping them as text
avoids that and still supports exact lookup, which is all the queries need. Sorting
the records gives a binary search per query, and the parent array is exactly the
"office is replaced by at most one other office" relation, so walking parents with
path compression gives the office the army uses. The step cap in `findTerminal`
keeps a cyclic list from looping forever.

## Code

```nim
import algorithm

type RecruitRecord = object
  pesel: string
  office: string

type RedirectionRecord = object
  oldOffice: string
  newOffice: string

var output: string

proc emit(text: string) =
  output.add(text)
  if output.len >= 1 shl 19:
    stdout.write(output)
    setLen(output, 0)

proc readLineText(): string =
  var current = ""
  discard stdin.readLine(current)
  return current

proc readDataLine(): string =
  var text = readLineText()
  while text.len == 0:
    text = readLineText()
  return text

proc readCount(text: string): int =
  var value = 0
  for i in 0 ..< text.len:
    if text[i] in {'0' .. '9'}:
      value = value * 10 + (text[i].ord - '0'.ord)
  return value

proc compareStrings(first: string, second: string): int =
  if first < second:
    return -1
  if first > second:
    return 1
  return 0

proc compareRecords(first: RecruitRecord, second: RecruitRecord): int =
  if first.pesel < second.pesel:
    return -1
  if first.pesel > second.pesel:
    return 1
  return 0

proc findIndex(values: var seq[string], wanted: string): int =
  var i = 0
  var j = values.len - 1
  while i <= j:
    let k = (i + j) div 2
    if values[k] == wanted:
      return k
    if values[k] < wanted:
      i = k + 1
    else:
      j = k - 1
  return -1

proc findTerminal(parent: var seq[int], node: int): int =
  var root = node
  var steps = 0
  while parent[root] >= 0 and steps <= parent.len:
    root = parent[root]
    steps += 1
  if steps > parent.len:
    return node
  var walker = node
  while walker != root:
    let next = parent[walker]
    if next < 0:
      break
    parent[walker] = root
    walker = next
  return root

let caseCount = readCount(readDataLine())
for j in 0 ..< caseCount:
  let listedCount = readCount(readDataLine())
  var records: seq[RecruitRecord]
  var officeCodes: seq[string]
  for _ in 0 ..< listedCount:
    let line = readDataLine()
    var i = 0
    while i < line.len and line[i] != ' ':
      i += 1
    let pesel = line[0 ..< i]
    let office = line[i + 1 ..< line.len]
    records.add(RecruitRecord(pesel: pesel, office: office))
    officeCodes.add(office)
  let redirectionCount = readCount(readDataLine())
  var redirections: seq[RedirectionRecord]
  for _ in 0 ..< redirectionCount:
    let line = readDataLine()
    var i = 0
    while i < line.len and line[i] != ' ':
      i += 1
    let oldOffice = line[0 ..< i]
    let newOffice = line[i + 1 ..< line.len]
    redirections.add(RedirectionRecord(oldOffice: oldOffice, newOffice: newOffice))
    officeCodes.add(oldOffice)
    officeCodes.add(newOffice)
  sort(officeCodes, compareStrings)
  var uniqueCodes: seq[string]
  for code in officeCodes:
    if uniqueCodes.len == 0 or uniqueCodes[^1] != code:
      uniqueCodes.add(code)
  sort(records, compareRecords)
  var parent: seq[int]
  setLen(parent, uniqueCodes.len)
  for i in 0 ..< parent.len:
    parent[i] = -1
  for record in redirections:
    let k = findIndex(uniqueCodes, record.oldOffice)
    let l = findIndex(uniqueCodes, record.newOffice)
    if k >= 0 and l >= 0:
      parent[k] = l
  let recruitCount = readCount(readDataLine())
  for _ in 0 ..< recruitCount:
    let pesel = readDataLine()
    var office = ""
    var i = 0
    var k = records.len - 1
    while i <= k:
      let l = (i + k) div 2
      if records[l].pesel == pesel:
        office = records[l].office
        break
      if records[l].pesel < pesel:
        i = l + 1
      else:
        k = l - 1
    var result = office
    let l = findIndex(uniqueCodes, office)
    if l >= 0:
      result = uniqueCodes[findTerminal(parent, l)]
    emit(pesel)
    emit(" ")
    emit(result)
    emit("\n")
  if j + 1 < caseCount:
    emit("\n")
stdout.write(output)
```

## Complexity

Building the tables costs O(p log p + m log m) with m the number of distinct office
codes, at most p + 2z. Each query costs O(log p + log m) plus almost O(1) for the
compressed parent walk, so the whole run stays near O((p + z + q) log(p + z)).
Memory is O(p + z).

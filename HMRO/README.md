# HMRO - Help the Military Recruitment Office!

## Problem

Each test case lists up to 100 000 boys with their PESEL code and their old
recruitment office code, then up to 100 000 redirections `old office new office`,
then up to 100 000 PESEL codes of the boys who are actually recruited. For every
recruited boy print the PESEL and the office code it reaches after following the
redirections. Test cases are separated by an empty line in the output.

## Idea

Every office code is given a slot in a table of all office codes of the test case,
and each redirection `old new` just writes `parent[old] = new`. Following a chain of
closures then becomes a `find` on that parent array, with path compression, so a
long chain is walked once and later queries jump straight to the final office.
Boys are found by sorting the PESEL records and binary searching them.

## Why It Works

PESEL codes are 11 digits, so they overflow a 32 bit integer; keeping them as text
avoids that and still supports exact lookup, which is all the queries need. Sorting
the records gives a binary search per query, and the parent array is exactly the
"office is replaced by at most one other office" relation, so walking parents with
path compression gives the office the army really uses. The step cap in `findTerminal`
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
  for index in 0 ..< text.len:
    if text[index] in {'0' .. '9'}:
      value = value * 10 + (text[index].ord - '0'.ord)
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
  var low = 0
  var high = values.len - 1
  while low <= high:
    let middle = (low + high) div 2
    if values[middle] == wanted:
      return middle
    if values[middle] < wanted:
      low = middle + 1
    else:
      high = middle - 1
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
for caseIndex in 0 ..< caseCount:
  let listedCount = readCount(readDataLine())
  var records: seq[RecruitRecord]
  var officeCodes: seq[string]
  for _ in 0 ..< listedCount:
    let line = readDataLine()
    var splitAt = 0
    while splitAt < line.len and line[splitAt] != ' ':
      splitAt += 1
    let pesel = line[0 ..< splitAt]
    let office = line[splitAt + 1 ..< line.len]
    records.add(RecruitRecord(pesel: pesel, office: office))
    officeCodes.add(office)
  let redirectionCount = readCount(readDataLine())
  var redirections: seq[RedirectionRecord]
  for _ in 0 ..< redirectionCount:
    let line = readDataLine()
    var splitAt = 0
    while splitAt < line.len and line[splitAt] != ' ':
      splitAt += 1
    let oldOffice = line[0 ..< splitAt]
    let newOffice = line[splitAt + 1 ..< line.len]
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
  for index in 0 ..< parent.len:
    parent[index] = -1
  for record in redirections:
    let oldIndex = findIndex(uniqueCodes, record.oldOffice)
    let newIndex = findIndex(uniqueCodes, record.newOffice)
    if oldIndex >= 0 and newIndex >= 0:
      parent[oldIndex] = newIndex
  let recruitCount = readCount(readDataLine())
  for _ in 0 ..< recruitCount:
    let pesel = readDataLine()
    var office = ""
    var low = 0
    var high = records.len - 1
    while low <= high:
      let middle = (low + high) div 2
      if records[middle].pesel == pesel:
        office = records[middle].office
        break
      if records[middle].pesel < pesel:
        low = middle + 1
      else:
        high = middle - 1
    var result = office
    let officeIndex = findIndex(uniqueCodes, office)
    if officeIndex >= 0:
      result = uniqueCodes[findTerminal(parent, officeIndex)]
    emit(pesel)
    emit(" ")
    emit(result)
    emit("\n")
  if caseIndex + 1 < caseCount:
    emit("\n")
stdout.write(output)
```

## Complexity

Building the tables costs O(p log p + m log m) with m the number of distinct office
codes, at most p + 2z. Each query costs O(log p + log m) plus almost O(1) for the
compressed parent walk, so the whole run stays near O((p + z + q) log(p + z)).
Memory is O(p + z).

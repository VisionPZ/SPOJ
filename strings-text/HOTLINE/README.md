# HOTLINE — Hotline (SPOJ)

<https://www.spoj.com/problems/HOTLINE/>

## Problem

A text module reads English sentences and remembers the facts they state. It must answer later questions from those remembered facts.

Read `t` dialogues. A dialogue starts with a count line. Statement lines end in `.`, question lines end in `?`, and one exit line ends in `!`.

Print the dialogue header, then each question, its answer, and a blank line. Close with the exit line and another blank line.

The bounds from the statement:

| Quantity | Bound |
| --- | --- |
| Dialogues per file | not fixed |
| Statements per dialogue | at most 100 |
| Line length | at most 100 characters |
| Time limit | 2000 ms |
| Memory limit | 1536 MB |

Statements never repeat inside one dialogue, so the fact store stays small.

The sample case:

```
1
I like hotdogs.
nobody likes to work.
everybody smiles.
what do I do?
who smiles?
what do you do?
does Joe smile?
do I like to work?
everybody hurts sometimes.
who walks there?
Michal walks there.
who walks there?
what does Michal do?
do you understand?
nobody walks there.
do you understand now?
bye!
```

```
Dialogue #1:
what do I do?
you like hotdogs, don't like to work, and smile.

who smiles?
everybody smiles.

what do you do?
I don't like to work, and smile.

does Joe smile?
yes, Joe smiles.

do I like to work?
no, you don't like to work.

who walks there?
I don't know.

who walks there?
Michal walks there.

what does Michal do?
Michal doesn't like to work, smiles, hurts sometimes, and walks there.

do you understand?
maybe.

do you understand now?
I am abroad.

bye!

```

## Idea

Treat each sentence as an index card with a subject, a verb, an object, and a sign.

The program files those cards, then pulls every card matching a question. This works like a waiting room where a nurse reads only the notes already on the clipboard. Three fixed templates turn the matching cards into yes/no, who, or what answers.

A positive and a negative card about the same activity cancel all trust. Every later answer then becomes `I am abroad`.

Each question scans the stored cards once, at O(S) cost for S statements. Building a fresh grammar per question costs far more. One scan over a small card pile answers every template.

## Why It Works

Five facts carry the answer rules.

1. An activity is the pair of base verb and object. `Michal walks there` and `everybody walks there` share the activity `walk / there`.
2. A verb loses its final `s` when the subject is not `I` or `you`, or when `nobody` acts. `baseVerb` restores that base form before matching.
3. A positive card applies to its named subject or to `everybody`. A negative card applies to its named subject or to `nobody`.
4. A generic card conflicts with every opposite card on the same activity. Two named subjects conflict only when equal, so `hasContradiction` scans pairs once.
5. The answer swaps `I` and `you`, because caller and operator speak from opposite sides. A single subject takes a singular verb; a list takes the base verb.

The fields and helpers and their roles:

| Term | Meaning |
| --- | --- |
| `Statement` | subject, base verb, object, and negation flag |
| `activityVerb` | verb stripped back to its dictionary form |
| `appliesTo` | test for a named or generic subject |
| `hasContradiction` | double scan for opposing cards |
| `swappedSubject` | `I` becomes `you`, and the reverse |
| `conjugatedVerb` | adds `s` for third-person singular subjects |

These rules keep grammar changes in one place per answer type.

A script traces the first three statements and the first question of the sample:

```
statement 1: I / like / hotdogs / positive
statement 2: nobody / like / to work / negative
statement 3: everybody / smile / (no object) / positive
question: what do I do?  -> answer subject "you"
matching facts: like hotdogs (+), like to work (-), smile (+)
answer: you like hotdogs, don't like to work, and smile.
```

The `nobody` card reaches `I`, so the answer includes `don't like to work`. The `everybody` card also reaches `I`, so `smile` joins the list.

## Code

**Types and line readers.** One buffer holds the whole file, and slices mark each line.

```nim
import std/strutils

const flushBlockBytes = 1 shl 18

type
  Statement = object
    subjectText: string
    activityVerb: string
    activityObject: string
    isNegative: bool

  QuestionKind = enum
    yesNoQuestion, whoQuestion, whatQuestion

  Question = object
    kind: QuestionKind
    subjectText: string
    activityVerb: string
    activityObject: string

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - 48
    i += 1
  return value

proc nextLine(data: string, i: var int): string =
  let j = i
  while i < data.len and data[i] != '\n':
    i += 1
  let result = data[j ..< i]
  if i < data.len:
    i += 1
  return result
```

The read loop runs once per input line and appends a newline each time. `nextLine` advances `i` past that newline, so lines never overlap. Both readers cost one pass over their bytes.

**Sentence parsing.** Each line becomes a fact or a question with fixed fields.

```nim
proc baseVerb(inflectedVerb: string): string =
  if inflectedVerb.len > 0 and inflectedVerb[inflectedVerb.len - 1] == 's':
    return inflectedVerb.substr(0, inflectedVerb.len - 2)
  return inflectedVerb

proc objectTail(parts: seq[string], i: int): string =
  var result = ""
  for j in i..<parts.len:
    if result.len > 0:
      result.add ' '
    result.add parts[j]
  return result

proc parseStatement(line: string): Statement =
  let content = line.substr(0, line.len - 2)
  let i = content.find(' ')
  result.subjectText = content.substr(0, i - 1)
  var remainder = content.substr(i + 1)
  if remainder.startsWith("don't "):
    result.isNegative = true
    remainder = remainder.substr(6)
  elif remainder.startsWith("doesn't "):
    result.isNegative = true
    remainder = remainder.substr(8)
  else:
    result.isNegative = result.subjectText == "nobody"
  let j = remainder.find(' ')
  if j < 0:
    result.activityVerb = remainder
    result.activityObject = ""
  else:
    result.activityVerb = remainder.substr(0, j - 1)
    result.activityObject = remainder.substr(j + 1)
  if result.subjectText == "nobody" or
     (not result.isNegative and result.subjectText != "I" and
      result.subjectText != "you"):
    result.activityVerb = baseVerb(result.activityVerb)

proc parseQuestion(line: string): Question =
  let content = line.substr(0, line.len - 2)
  let parts = content.split(' ')
  if parts[0] == "who":
    result.kind = whoQuestion
    result.activityVerb = baseVerb(parts[1])
    result.activityObject = objectTail(parts, 2)
  elif parts[0] == "what":
    result.kind = whatQuestion
    result.subjectText = parts[2]
  else:
    result.kind = yesNoQuestion
    result.subjectText = parts[1]
    result.activityVerb = parts[2]
    result.activityObject = objectTail(parts, 3)
```

`substr(0, line.len - 2)` drops the final dot or question mark. The two negative auxiliaries differ in length, so each gets its own offset. The object keeps its spaces as one string.

**Fact matching.** Applicability and contradictions use the stored cards.

```nim
proc sameActivity(left: Statement, verb: string, objectText: string): bool =
  return left.activityVerb == verb and left.activityObject == objectText

proc appliesTo(statement: Statement, subject: string): bool =
  if statement.isNegative:
    return statement.subjectText == subject or statement.subjectText == "nobody"
  return statement.subjectText == subject or statement.subjectText == "everybody"

proc hasContradiction(statements: seq[Statement]): bool =
  for positive in statements:
    if positive.isNegative:
      continue
    for negative in statements:
      if not negative.isNegative:
        continue
      if not sameActivity(negative, positive.activityVerb, positive.activityObject):
        continue
      if positive.subjectText == "everybody" or negative.subjectText == "nobody" or
         positive.subjectText == negative.subjectText:
        return true
  return false
```

A generic card meets every opposite card about the same activity. Named subjects meet only when equal. The double scan costs O(S^2) for at most 100 statements.

**Grammar helpers and yes/no.** The reply swaps viewpoints and fixes the verb.

```nim
proc swappedSubject(subject: string): string =
  if subject == "I":
    return "you"
  if subject == "you":
    return "I"
  return subject

proc conjugatedVerb(verb: string, subject: string): string =
  if subject == "I" or subject == "you":
    return verb
  return verb & "s"

proc withObject(text: string, objectText: string): string =
  if objectText.len == 0:
    return text
  return text & " " & objectText

proc yesNoAnswer(question: Question, statements: seq[Statement]): string =
  let answerSubject = swappedSubject(question.subjectText)
  var positiveFound = false
  var negativeFound = false
  for statement in statements:
    if not appliesTo(statement, question.subjectText):
      continue
    if not sameActivity(statement, question.activityVerb, question.activityObject):
      continue
    if statement.isNegative:
      negativeFound = true
    else:
      positiveFound = true
  if positiveFound:
    return "yes, " & withObject(answerSubject & " " &
                                conjugatedVerb(question.activityVerb, answerSubject),
                                question.activityObject) & "."
  if negativeFound:
    let denial = if answerSubject == "I" or answerSubject == "you":
                   "don't"
                 else:
                   "doesn't"
    return "no, " & withObject(answerSubject & " " & denial & " " &
                               question.activityVerb, question.activityObject) & "."
  return "maybe."
```

A positive card wins over a negative card, and silence gives `maybe.`. The scan visits each card once. `withObject` appends the object only when one exists.

**Who and what answers.** Enumerations and activity lists follow two templates.

```nim
proc whoAnswer(question: Question, statements: seq[Statement]): string =
  var matchingSubjects: seq[string] = @[]
  var nobodyFound = false
  for statement in statements:
    if not sameActivity(statement, question.activityVerb, question.activityObject):
      continue
    if statement.isNegative:
      if statement.subjectText == "nobody":
        nobodyFound = true
    else:
      matchingSubjects.add statement.subjectText
  var everybodyFound = false
  for subject in matchingSubjects:
    if subject == "everybody":
      everybodyFound = true
  if everybodyFound:
    return "everybody " & withObject(conjugatedVerb(question.activityVerb,
                                                    "everybody"),
                                      question.activityObject) & "."
  if matchingSubjects.len > 0:
    var enumerated = ""
    for i in 0..<matchingSubjects.len:
      let displaySubject = swappedSubject(matchingSubjects[i])
      if i == 0:
        enumerated = displaySubject
      elif i == matchingSubjects.len - 1:
        enumerated = enumerated & " and " & displaySubject
      else:
        enumerated = enumerated & ", " & displaySubject
    var answerVerb = question.activityVerb
    if matchingSubjects.len == 1:
      answerVerb = conjugatedVerb(question.activityVerb,
                                  swappedSubject(matchingSubjects[0]))
    return enumerated & " " & withObject(answerVerb,
                                          question.activityObject) & "."
  if nobodyFound:
    return withObject("nobody " & conjugatedVerb(question.activityVerb, "nobody"),
                      question.activityObject) & "."
  return "I don't know."

proc whatAnswer(question: Question, statements: seq[Statement]): string =
  let answerSubject = swappedSubject(question.subjectText)
  let denial = if answerSubject == "I" or answerSubject == "you":
                 "don't"
               else:
                 "doesn't"
  var seenVerbs: seq[string] = @[]
  var seenObjects: seq[string] = @[]
  var pieces: seq[string] = @[]
  for statement in statements:
    if not appliesTo(statement, question.subjectText):
      continue
    var alreadySeen = false
    for i in 0..<seenVerbs.len:
      if seenVerbs[i] == statement.activityVerb and
         seenObjects[i] == statement.activityObject:
        alreadySeen = true
        break
    if alreadySeen:
      continue
    seenVerbs.add statement.activityVerb
    seenObjects.add statement.activityObject
    var piece: string
    if statement.isNegative:
      piece = denial & " " & statement.activityVerb
    else:
      piece = conjugatedVerb(statement.activityVerb, answerSubject)
    pieces.add withObject(piece, statement.activityObject)
  if pieces.len == 0:
    return "I don't know."
  var answer = answerSubject & " " & pieces[0]
  if pieces.len == 2:
    answer = answer & ", and " & pieces[1]
  elif pieces.len > 2:
    for i in 1..<pieces.len - 1:
      answer = answer & ", " & pieces[i]
    answer = answer & ", and " & pieces[pieces.len - 1]
  return answer & "."
```

A `who` list joins names with commas and one final `and`. A `what` list puts a comma before `and`. Duplicate activities never appear twice.

**Driver.** The loop reads lines in order and flushes output in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var j = 0
let headerLine = nextLine(inputData, j)
j = 0
let caseCount = nextInt(headerLine, j)

for k in 1..caseCount:
  appendOutput("Dialogue #")
  outputBuffer.add $k
  outputBuffer.add ":\n"
  var statements: seq[Statement] = @[]
  while true:
    let dialogueLine = nextLine(inputData, i)
    if dialogueLine.len == 0:
      if i >= inputData.len:
        break
      continue
    let l = dialogueLine.len - 1
    if dialogueLine[l] == '!':
      appendOutput(dialogueLine)
      outputBuffer.add '\n'
      outputBuffer.add '\n'
      break
    if dialogueLine[l] == '.':
      statements.add parseStatement(dialogueLine)
    elif dialogueLine[l] == '?':
      appendOutput(dialogueLine)
      outputBuffer.add '\n'
      var answer: string
      if hasContradiction(statements):
        answer = "I am abroad."
      else:
        let question = parseQuestion(dialogueLine)
        case question.kind
        of yesNoQuestion:
          answer = yesNoAnswer(question, statements)
        of whoQuestion:
          answer = whoAnswer(question, statements)
        of whatQuestion:
          answer = whatAnswer(question, statements)
      appendOutput(answer)
      outputBuffer.add '\n'
      outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Statements accumulate only inside the current dialogue. The contradiction check runs before each answer, so later facts cannot rewrite earlier replies.

## Complexity

Parsing and answering both stay small for at most 100 statements.

| Phase | Time | Space |
| --- | --- | --- |
| Parse one line | O(line length) | O(object length) |
| Store S statements | O(S) | O(S) cards |
| Answer one question | O(S^2) worst case | O(S) scratch lists |
| Output | O(1) per line | one output block |

The worst answer cost comes from the contradiction double scan.

| Measure | Big O |
| --- | --- |
| Time | O(Q * S^2) per dialogue, with S at most 100 |
| Space | O(S) per dialogue plus the input buffer |

A fresh grammar or full reparsing for each question costs far more than one scan of the card pile.

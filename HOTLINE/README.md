## Problem

Read several dialogues in English. Each dialogue contains statements that end with a dot and questions that end with a question mark. A special line ending with an exclamation mark closes the dialogue. Answer each question using only the statements that came before it. Print the dialogue header, then for every question its text, the answer, and an empty line. Close with the exclamation line and another empty line.

| Quantity | Bound |
| --- | --- |
| Dialogues per file | not fixed |
| Statements per dialogue | at most 100 |
| Line length | at most 100 characters |
| Time limit | 2000 ms |
| Memory limit | 1536 MB |

Statements never repeat inside one dialogue; questions may repeat.

## Idea

Store each statement as a subject, a base verb, an object, and a polarity. A question looks up statements whose subject matches, including the generic subjects `everybody` and `nobody`. When a positive and a negative statement describe the same activity for the same subject, every later answer becomes `I am abroad.`

Each question scans the stored statements once, so answering costs O(S) for S statements. Searching a fresh grammar for every question would cost far more.

## Why It Works

An activity is the pair of base verb and object. `Michal walks there` and `everybody walks there` share the activity `walk / there`. The inflected verb loses its final `s` when the subject is not `I` or `you`, and when the subject is `nobody`.

The three question types follow fixed templates:

- yes or no: look for a matching positive statement, then a matching negative one, then answer `maybe.`
- who: collect the subjects of matching positive statements, or fall back to a `nobody` statement
- what: list every distinct activity that applies to the subject, in statement order

The answer subject swaps `I` and `you`, because the caller and the operator see each other from opposite sides. A single subject uses the singular verb; an enumeration uses the base verb. A contradiction means the stored facts cannot all hold, so no other answer is trustworthy.

## Code

The program reads all input at once and keeps each line as a slice.

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

The header is read with a separate position, so the dialogue walk starts at the first line after it. Parsing one line visits its characters once.

The next helpers convert a raw line into a fact or a question.

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

The object keeps its spaces and punctuation as one string. The two negative auxiliaries have different lengths, so each uses its own offset.

The fact store decides applicability and contradictions.

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

A generic statement conflicts with every opposite statement about the same activity. Two specific subjects conflict only when they are equal. The double scan costs O(S²) for at most 100 statements.

Each answer builder follows one question template.

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

A who enumeration joins subjects with commas and one final `and`. A what list uses a comma before `and` instead. Duplicate activities are skipped even when two generic statements describe them.

The driver processes lines in order and flushes output in blocks.

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

Statements accumulate only inside the current dialogue. The contradiction check runs before each answer, so facts added later cannot change earlier replies.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| Parse one line | O(line length) | O(object length) |
| Store S statements | O(S) | O(S) |
| Answer one question | O(S²) worst case | O(S) |
| Output | O(1) per line | one block |

Total time per dialogue is O(Q · S²) for Q questions and S statements, with S at most 100. Total space is O(S) for statements plus the input buffer.

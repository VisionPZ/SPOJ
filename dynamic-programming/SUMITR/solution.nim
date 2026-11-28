import strutils,sequtils
var s=stdin.readAll
var a=s.splitWhitespace.map(parseInt)
var p=1
for _ in 1..a[0]:
 let r=a[p];p+=1
 for k in countdown(r-2,0):
  let t=p+k*(k+1)div 2
  for j in 0..k:a[t+j]+=max(a[t+k+1+j],a[t+k+2+j])
 echo a[p];p+=r*(r+1)div 2
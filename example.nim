import poly, async

# demonstrating args and pragma check

type
  AKind* = enum A1, A2
  
  A* = ref object
    case kind*: AKind:
    of A1:
      a1*: int
    of A2:
      a2*: int

poly:
  proc display*(a: A{kind: A1}, b: string) {.async.} =
    echo b, " ", a.a1


  proc display*(a: A{kind: A2}, b: string) {.async.} =
    echo b, " ", a.a2



proc run {.async.} = 
  var a = A(kind: A1, a1: 42)
  var other = A(kind: A2, a2: 64)
  
  await a.display("tiger")
  await other.display("panda")

discard run()


# poly
 
A nim library for variant-based overloading 


## example

```nim
poly:
  proc display*(a: A{kind: A1}, b: string) {.async.} =
    echo b, " ", a.a1


  proc display*(a: A{kind: A2}, b: string) {.async.} =
    echo b, " ", a.a2

# equivalent to

# proc display*(a: A; b: string) {.async.} =
#   case a.kind
#   of A1:
#     echo b, " ", a.a1
#   of A2:
#     echo b, " ", a.a2

```

(full in `example.nim`)

Poly checks that args, return and pragmas in overloads are the same.
If you just pass `a: A`, you can generate `else`

If I have a lot of logic for each variant, `of` gets messy and I have to 
refactor it in functions.
Then I need to manually dispatch to those functions in `case` and to do `assert` in them in order to have type safety: with poly I just need to write the kind in signatures

## name

I can't think of another name: poly,morphism

## future

probably one can add support for full pattern matching, 
e.g.

```nim
poly:
  proc display*(a: A{e: 4, h > 2}) =
    echo a.e
```

generating if

However maybe [patty](https://github.com/andreaferretti/patty) is a better place for that

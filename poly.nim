import macros


proc name*(procedure: NimNode): string =
  let first = procedure[0]
  if first.kind == nnkPostfix:
    if first[1].kind == nnkIdent:
      result = $first[1]
    elif first[1].kind == nnkAccQuoted and first[1][0].kind == nnkIdent:
      result = $first[1][0]
    else:
      error("no name")
  elif first.kind == nnkAccQuoted and first[0].kind == nnkIdent:
    result = $first[0]
  elif first.kind == nnkIdent:
    result = $first
  else:
    error("no name")


proc exported*(procedure: NimNode): bool =
  procedure[0].kind == nnkPostfix and procedure[0][0].kind == nnkIdent and $procedure[0][0] == "*"


proc extractType(arg: NimNode): (string, string, NimNode) =
  if arg.kind == nnkIdent:
    result = ($arg, "", ident("default"))
  elif arg.kind == nnkCurlyExpr and arg[0].kind == nnkIdent:
    result = ($arg[0], $arg[1][0], arg[1][1])
  else:
    error("invalid type")


macro poly*(overloads: untyped): untyped =
  expectKind(overloads, nnkStmtList)
  if overloads.len == 0:
    error("expected at least one")

  var polyName = ""
  var polyVar = ""
  var polyVariant = ""
  var polyKind = ""
  var polyExported = false
  var polyArgs = nnkFormalParams.newTree()
  var polyReturn = newEmptyNode()
  var polyPragma = newEmptyNode()
  var polyCode = nnkStmtList.newTree()
    
  var z = 0
  for overload in overloads:
    expectKind(overload, nnkProcDef)
    
    let name = overload.name()
    if polyName == "":
      polyName = name
    elif polyName != name:
      error("expected " & polyName & ", got " & name)
      
    let exported = overload.exported()
    if z == 0:
      polyExported = exported
    elif polyExported != exported:
      error("export changed")
    
    if overload[3].len == 1:
      error("expected at least 1 arg")
    
    let variantArg = overload[3][1]
    
    if polyVar == "":
      polyVar = $variantArg[0]
    elif polyVar != $variantArg[0]:
      error("expected " & polyVar & ", got " & $variantArg[0])

    let (variant, kind, value) = extractType(variantArg[1])
    if polyVariant == "":
      polyVariant = variant
    elif polyVariant != variant:
      error("expected " & polyVariant & ", got " & $variant)
    if polyKind == "":
      polyKind = kind
    elif polyKind != kind and kind != "":
      error("expected " & polyKind & ", got " & $kind)
    
    if polyArgs.len == 0:
      polyArgs.add(newEmptyNode(), nnkIdentDefs.newTree(ident(polyVar), ident(polyVariant), newEmptyNode()))
      var y = 0
      for arg in overload[3]:
        if y >= 2:
          polyArgs.add(arg)
        y += 1
    elif polyArgs.len != overload[3].len:
      error("expected " & $(polyArgs.len - 1) & " args, got " & $(overload[3].len - 1))

    if z == 0:
      polyReturn = overload[3][0]
    elif polyReturn != overload[3][0]:
      error("expected " & polyReturn.repr & " , got " & overload[3][0].repr)

    if z == 0:
      polyPragma = overload[4]
    elif polyPragma != overload[4]:
      error("expected " & polyPragma.repr & " , got " & overload[4].repr)

    if z == 0:
      polyCode = nnkCaseStmt.newTree(
        nnkDotExpr.newTree(
          ident(polyVar),
          ident(polyKind)))

    if z == 0 and kind == "":
      polyCode = overload[^1]
    elif kind != "":
      polyCode.add(
        nnkOfBranch.newTree(
          value,
          overload[^1]))
    else:
      polyCode.add(
        nnkElse.newTree(
          overload[^1]))


    z += 1
    
  # proc `polyName`*(`polyArgs`): `polyReturn` `polyPragma` =
  #   case `polyVar`.`polyKind`:
  #     of `value`:
  #       `code`
  #     of `value`:
  #        `code`

  let nameNode = if polyExported:
    nnkPostfix.newTree(ident("*"), ident(polyName))
  else: 
    ident(polyName)  
  polyArgs[0] = polyReturn
  
  result = nnkProcDef.newTree(
    nameNode,
    newEmptyNode(),
    newEmptyNode(),
    polyArgs,
    polyPragma,
    newEmptyNode(),
    nnkStmtList.newTree(polyCode))

  # echo result.repr

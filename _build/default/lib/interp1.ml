include Utils

let parse (s : string) : expr option =
  match Parser.prog Lexer.read (Lexing.from_string s) with
  | e -> Some e
  | exception _ -> None

let rec subst (v : value) (x : string) (e : expr) : expr =
  let unwrappedv = match v with
    | VUnit -> Unit
    | VBool b -> if b then True else False
    | VNum n -> Num n
    | VFun (arg, body) -> Fun (arg, body)
  in
  match e with
  | Var y -> if x = y then unwrappedv else e (* if e is a var and it is the same as string x then it'll be value of v *)
  | Num _ | True | False | Unit -> e (* literals *)
  | Bop (op, e1, e2) -> Bop (op, subst v x e1, subst v x e2) (* recurse *)
  | If (e1, e2, e3) -> If (subst v x e1, subst v x e2, subst v x e3) (* same here *)
  | App (e1, e2) -> App (subst v x e1, subst v x e2) (* function application, same recursive logic as above *)
  | Let (y, e1, e2) -> let e1' = subst v x e1 in  (* substitute in e1 first because e1 is a bound expression *)
    if y = x then
      Let (y, e1', e2) (* var x is shadowed in e2, do not substitute e2 *)
    else
      Let (y, e1', subst v x e2) (* substitute because x not shadowed by y *)
  | Fun (y, e1) ->
    if y = x then
      Fun (y, e1) (* same logic as above *)
    else
      Fun (y, subst v x e1)

  

let rec eval (e : expr) : (value, error) result =
  match e with 
  (* literals first *)
  (* int lit *)
  | Num n -> Ok (VNum n) 
  (* true eval *)
  | True -> Ok (VBool true) 
  (*  false eval *)
  | False -> Ok (VBool false)
  (* unit eval *)
  | Unit -> Ok VUnit
  (* Arithmatics operators *)
  | Bop (Add, e1, e2) -> 
      (match eval e1, eval e2 with
       | Ok (VNum n1), Ok (VNum n2) -> Ok (VNum (n1 + n2))
       | Ok _, Ok _ -> Error (InvalidArgs Add)
       | Error e, _ | _, Error e -> Error e)
  | Bop (Sub, e1, e2) ->
      (match eval e1, eval e2 with
       | Ok (VNum n1), Ok (VNum n2) -> Ok (VNum (n1 - n2))
       | Ok _, Ok _ -> Error (InvalidArgs Sub)
       | Error e, _ | _, Error e -> Error e)
  | Bop (Mul, e1, e2) ->
      (match eval e1, eval e2 with
       | Ok (VNum n1), Ok (VNum n2) -> Ok (VNum (n1 * n2))
       | Ok _, Ok _ -> Error (InvalidArgs Mul)
       | Error e, _ | _, Error e -> Error e)
  | Bop (Div, e1, e2) ->
      (match eval e1, eval e2 with
       | Ok (_), Ok (VNum 0) -> Error DivByZero
       | Ok (VNum n1), Ok (VNum n2) -> Ok (VNum (n1 / n2))
       | Ok _, Ok _ -> Error (InvalidArgs Div)
       | Error e, _ | _, Error e -> Error e)
  | Bop (Mod, e1, e2) ->
      (match eval e1, eval e2 with
       | Ok (_), Ok (VNum 0) -> Error DivByZero
       | Ok (VNum n1), Ok (VNum n2) -> Ok (VNum (n1 mod n2))
       | Ok _, Ok _ -> Error (InvalidArgs Mod)
       | Error e, _ | _, Error e -> Error e)
  (* Comparison operators *)
  | Bop (Lt, e1, e2) ->
      (match eval e1, eval e2 with
       | Ok (VNum n1), Ok (VNum n2) -> Ok (VBool (n1 < n2))
       | Ok _, Ok _ -> Error (InvalidArgs Lt)
       | Error e, _ | _, Error e -> Error e)
  | Bop (Lte, e1, e2) ->
      (match eval e1, eval e2 with
       | Ok (VNum n1), Ok (VNum n2) -> Ok (VBool (n1 <= n2))
       | Ok _, Ok _ -> Error (InvalidArgs Lte)
       | Error e, _ | _, Error e -> Error e)
  | Bop (Gt, e1, e2) ->
      (match eval e1, eval e2 with
       | Ok (VNum n1), Ok (VNum n2) -> Ok (VBool (n1 > n2))
       | Ok _, Ok _ -> Error (InvalidArgs Gt)
       | Error e, _ | _, Error e -> Error e)
  | Bop (Gte, e1, e2) ->
      (match eval e1, eval e2 with
       | Ok (VNum n1), Ok (VNum n2) -> Ok (VBool (n1 >= n2))
       | Ok _, Ok _ -> Error (InvalidArgs Gte)
       | Error e, _ | _, Error e -> Error e)
  | Bop (Eq, e1, e2) ->
      (match eval e1, eval e2 with
       | Ok v1, Ok v2 -> Ok (VBool (v1 = v2)) (* value equality *)
       | Error e, _ | _, Error e -> Error e)
  | Bop (Neq, e1, e2) ->
      (match eval e1, eval e2 with
       | Ok v1, Ok v2 -> Ok (VBool (v1 <> v2)) (* value inequality *)
       | Error e, _ | _, Error e -> Error e)
  (* Logical operators *)
  | Bop (And, e1, e2) ->
      (match eval e1 with
       | Ok (VBool true) -> eval e2 (* if e1 is true, then check if e2 is also true *)
       | Ok (VBool false) -> Ok (VBool false) (* if e1 is false then whole expr is false*)
       | Error e -> Error e
       | _ -> Error (InvalidArgs And))
  | Bop (Or, e1, e2) ->
      (match eval e1 with
       | Ok (VBool true) -> Ok (VBool true) (* if e1 is true then whole expr is true *)
       | Ok (VBool false) -> eval e2
       | Error e -> Error e
       | _ -> Error (InvalidArgs Or))
  (* If expression *)
  | If (cond, e1, e2) ->
      (match eval cond with
       | Ok (VBool true) -> eval e1 (* ifTrueEval *)
       | Ok (VBool false) -> eval e2 (* ifFalseEval *)
       | Error e -> Error e
       | _ -> Error InvalidIfCond) (* non-boolean condition *)
  (* Let expression *)
  | Let (x, e1, e2) ->
      (match eval e1 with
       | Ok v1 -> eval (subst v1 x e2) (* letEval subst the val of e1 into e2 *)
       | Error e -> Error e)
  (* Function definition *)
  | Fun (x, body) -> Ok (VFun (x, body)) (* funEval *)
  (* appEval *)
  | App (e1, e2) ->
    (match eval e1 with
    | Error err -> Error err
    | Ok (VFun (x, body)) -> (* turn e1 eval to a Vfun *)
        (match eval e2 with (* now for e2 *)
        | Error err -> Error err
        | Ok v2 ->
            let body' = subst v2 x body in (* follow semantics rules *)
            eval body' (*  *)
        )
    | Ok _ -> Error InvalidApp (* e1 did not eval to a fun then invalid *)
    )
  | Var x ->
    Error (UnknownVar x) (* wasnt in semantic rules so unknown to get rid of not exhaustive case *)

  


let interp (s : string) : (value, error) result =
  match parse s with
  | Some e -> eval e
  | None -> Error ParseFail

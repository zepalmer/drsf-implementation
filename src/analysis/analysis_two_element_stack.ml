open Batteries;;

open Analysis_context_stack;;
open Cba_graph;;

module Stack : Context_stack =
struct
  type t = S of abstract_clause list;;
  let compare = compare;;
  let empty = S([]);;
  let push c (S(lst)) =
    match lst with
      | [] -> S([c])
      | h::_ -> S([c;h])
  ;;
  let pop (S(lst)) =
    match lst with
      | [] -> S([])
      | _::t -> S(t)
  ;;
  let is_top c (S(c_option)) =
    match c_option with
    | h::_ -> c = h
    | [] -> true
  ;;
  let pretty (S(lst)) =
    let pfx =
      List.fold_left (fun a c -> a ^ pp_abstract_clause c ^ "|") "" lst
    in
    pfx ^ "?"
  ;;
end;;
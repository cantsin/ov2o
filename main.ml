(* open Icalendar *)

let is_vcf filename = Filename.check_suffix filename ".vcf"

let traverse dir predicate =
  let rec loop result = function
    | f::fs when Sys.is_directory f ->
       Sys.readdir f
       |> Array.to_list
       |> List.map (Filename.concat f)
       |> List.append fs
       |> loop result
    | f::fs ->
       loop (if predicate f then f::result else result) fs
    | [] -> result
  in
  loop [] [dir]

let discover path =
  let files = traverse path is_vcf in
  List.iter (Printf.printf "%s ") files
;;

discover "/home/james/.calendar";;
(* TODO: command line args *)

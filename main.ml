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

let debug cal = Format.asprintf "%a" Icalendar.pp cal

let extract filename =
  let cal = Core.In_channel.read_all filename
            |> Icalendar.parse
            |> Result.get_ok in
  let events = cal
               |> snd
               |> List.filter_map (function `Event e -> Some e | _ -> None) in
  if List.length events > 1 then
    failwith (Printf.sprintf "more than one event not supported (%s)" (debug cal))
  else
    (* extract dtstart, dtend_or_duration, props/summary props/description *)
    ()

let discover path =
  let files = traverse path is_vcf in
  List.iter extract files
;;

discover "/home/james/.calendar";;
(* TODO: command line args *)
(* - date range: +/- 7 days

 * - VEVENT/SUMMARY
 * - VEVENT/DTSTART and VEVENT/DTEND (depending on timezone)
 *   in <org-date>--<org date> format
 * - VEVENT/DESCRIPTION *)

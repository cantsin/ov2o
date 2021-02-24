open Core

let is_vcf filename = Filename.check_suffix filename ".vcf"

let traverse dir predicate =
  let rec loop result = function
    | f::fs when phys_equal (Sys.is_directory f) `Yes ->
       Sys.ls_dir f
       |> List.map ~f:(Filename.concat f)
       |> List.append fs
       |> loop result
    | f::fs ->
       loop (if predicate f then f::result else result) fs
    | [] -> result
  in
  loop [] [dir]

let debug cal = Format.asprintf "%a" Icalendar.pp cal

(* let to_ptime (value: Icalendar.params * Icalendar.date_or_datetime): Ptime.t =
 *   () *)

let get_description (event: Icalendar.event): string =
  List.find_map event.props ~f:(function `Summary s -> Some (snd s) | _ -> None)
  |> Option.value ~default:"(No summary)"

let extract filename =
  Core.In_channel.read_all filename
  |> Icalendar.parse
  |> Result.ok_or_failwith
  |> snd
  |> List.filter_map ~f:(function `Event e -> Some e | _ -> None)
  |> List.map ~f:(function (event: Icalendar.event) ->
                    (event.dtstart,
                     event.dtend_or_duration,
                     get_description event))

(* - VEVENT/SUMMARY
 * - VEVENT/DTSTART and VEVENT/DTEND (depending on timezone)
 *   in <org-date>--<org date> format
 * - VEVENT/DESCRIPTION *)
(* let output event =
 *   () *)

let discover path _ _ =
  let (_: 'a list) = traverse path is_vcf
          |> List.map ~f:extract
          |> List.fold ~init:[] ~f:List.append in
  (* filter date range: +/- 7 days *)
  Printf.printf "done"
;;

let command =
  Command.basic
    ~summary:"Summarize iCalendar files into Org format."
    Command.Let_syntax.(
      let%map_open
            path = anon ("path" %: string)
      and days_behind = anon ("days_behind" %: int)
      and days_after = anon ("days_after" %: int) in
      fun () -> discover path days_behind days_after)

let () =
  Command.run ~version:"1.0" command

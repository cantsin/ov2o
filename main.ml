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

let get_datetime = function
    `Date d -> Ptime.of_date d |> Option.value ~default:Ptime.min
  | `Datetime ts ->
     match ts with
       `With_tzid (t, _) -> t (* TODO: adjust for timezone *)
     | `Utc u -> u
     | `Local l -> l

let get_start (event: Icalendar.event): Ptime.t =
  snd event.dtstart |> get_datetime

let get_end (event: Icalendar.event): Ptime.t =
  match event.dtend_or_duration with
    None -> Ptime.min
  | Some time -> match time with
                   `Dtend ts -> snd ts |> get_datetime
                 | `Duration _ -> Ptime.min (* TODO: support this use case *)

let get_description (event: Icalendar.event): string =
  let x = List.find_map event.props ~f:(function `Summary s -> Some (snd s) | _ -> None)
  |> Option.value ~default:"(No summary)" in
  let () = Printf.printf "%s" x in x

let extract filename =
  Core.In_channel.read_all filename
  |> Icalendar.parse
  |> Result.ok_or_failwith
  |> snd
  |> List.filter_map ~f:(function `Event e -> Some e | _ -> None)
  |> List.map ~f:(function (event: Icalendar.event) ->
                    (get_start event,
                     get_end event,
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

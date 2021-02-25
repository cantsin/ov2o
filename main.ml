open Core

let is_vcf filename = Filename.check_suffix filename ".vcf"

let traverse dir predicate =
  let rec loop result = function
    | f :: fs when phys_equal (Sys.is_directory f) `Yes ->
        Sys.ls_dir f
        |> List.map ~f:(Filename.concat f)
        |> List.append fs |> loop result
    | f :: fs -> loop (if predicate f then f :: result else result) fs
    | [] -> result
  in
  loop [] [ dir ]

let of_ptime ?default:(v = Ptime.min) = function
  | Some t -> t
  | None ->
      let () = Printf.printf "warning: invalid time option\n" in
      v

let get_datetime = function
  | `Date d -> Ptime.of_date d |> of_ptime
  | `Datetime ts -> (
      match ts with
      | `With_tzid (t, _) -> t (* TODO: adjust for timezone *)
      | `Utc u -> u
      | `Local l -> l)

let get_start (event : Icalendar.event) : Ptime.t =
  snd event.dtstart |> get_datetime

let get_end (event : Icalendar.event) : Ptime.t =
  match event.dtend_or_duration with
  | None -> Ptime.min
  | Some time -> (
      match time with
      | `Dtend ts -> snd ts |> get_datetime
      | `Duration (_, span) -> Ptime.add_span (get_start event) span |> of_ptime
      )

let get_summary (event : Icalendar.event) : string =
  List.find_map event.props ~f:(function
    | `Summary s -> Some (snd s)
    | _ -> None)
  |> Option.value ~default:"(No summary)"

let get_description (event : Icalendar.event) : string =
  List.find_map event.props ~f:(function
    | `Description d -> Some (snd d)
    | _ -> None)
  |> Option.value ~default:"(No description)"

let extract filename =
  Core.In_channel.read_all filename
  |> Icalendar.parse |> Result.ok_or_failwith |> snd
  |> List.filter_map ~f:(function `Event e -> Some e | _ -> None)

let to_org_datetime p =
  let (y, m, d), ((hh, mm, _), _) = Ptime.to_date_time p in
  let weekday =
    match Ptime.weekday p with
    | `Sun -> "Sun"
    | `Mon -> "Mon"
    | `Tue -> "Tue"
    | `Wed -> "Wed"
    | `Thu -> "Thu"
    | `Fri -> "Fri"
    | `Sat -> "Sat"
  in
  Printf.sprintf "%.4d-%.2d-%.2d %s %.2d:%.2d" y m d weekday hh mm

let to_org event =
  Printf.printf "* %s\n  - %s\n  - <%s>--<%s>\n" (get_summary event)
    (get_description event)
    (get_start event |> to_org_datetime)
    (get_end event |> to_org_datetime)

let day_span days =
  match Ptime.Span.of_d_ps (days, 0L) with
  | Some s -> s
  | None -> failwith "invalid day span"

let now () =
  let t = Date.today ~zone:Time.Zone.utc in
  match
    Ptime.of_date (Date.year t, Date.month t |> Month.to_int, Date.day t)
  with
  | Some t -> t
  | None -> failwith "now"

let discover path days_behind days_after =
  let today = now () in
  let behind = day_span days_behind |> Ptime.sub_span today |> of_ptime in
  let after =
    day_span days_after |> Ptime.add_span today |> of_ptime ~default:Ptime.max
  in
  traverse path is_vcf |> List.map ~f:extract
  |> List.fold ~init:[] ~f:List.append (* flatten *)
  (* TODO: sort by date? *)
  |> List.filter ~f:(function event ->
         let t = get_start event in
         Ptime.is_later t ~than:behind && Ptime.is_earlier t ~than:after)
  |> List.iter ~f:to_org

let command =
  Command.basic ~summary:"Summarize iCalendar files into Org format."
    Command.Let_syntax.(
      let%map_open path = anon ("path" %: string)
      and days_behind = anon ("days_behind" %: int)
      and days_after = anon ("days_after" %: int) in
      fun () -> discover path days_behind days_after)

let () = Command.run ~version:"1.0" command

(* TODO: test duration *)
(* TODO: test timezones *)
(* TODO: recurrences? *)

open Core

let local_tz = Time.Zone.local |> Lazy.force

let tz_offset_in_seconds tz =
  Time.utc_offset Time.epoch ~zone:tz |> Time.Span.to_sec

let local_tz_offset = tz_offset_in_seconds local_tz

let offset_tz tz =
  let tz_offset = tz_offset_in_seconds tz in
  match Time.Zone.compare local_tz tz with
  | 0 -> 0
  | 1 -> tz_offset -. local_tz_offset |> int_of_float
  | _ -> local_tz_offset -. tz_offset |> int_of_float

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

let get_datetime = function
  | `Date d -> Ptime.of_date d |> Option.value_exn
  | `Datetime ts -> (
      match ts with
      | `With_tzid (t, (_, z)) ->
        let offset =
          (* hack *)
          let tz = if equal_string z "Pacific Standard Time" then "America/Los_Angeles" else z in
          Time.Zone.find_exn tz |> offset_tz |> Ptime.Span.of_int_s
        in
        Ptime.add_span t offset |> Option.value_exn
      | `Utc u ->
        Ptime.to_float_s u +. local_tz_offset |> Ptime.of_float_s |> Option.value_exn
      | `Local l -> l)

let get_start (event : Icalendar.event) : Ptime.t =
  snd event.dtstart |> get_datetime

let get_end (event : Icalendar.event) : Ptime.t =
  match event.dtend_or_duration with
  | None -> Ptime.min
  | Some time -> (
      match time with
      | `Dtend ts -> snd ts |> get_datetime
      | `Duration (_, span) -> Ptime.add_span (get_start event) span |> Option.value_exn
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

let day_span days = Ptime.Span.of_d_ps (days, 0L) |> Option.value_exn

let now () =
  let t = Date.today ~zone:Time.Zone.utc in
  Ptime.of_date (Date.year t, Date.month t |> Month.to_int, Date.day t) |> Option.value_exn

let discover path days_behind days_after =
  let today = now () in
  let behind = day_span days_behind |> Ptime.sub_span today |> Option.value_exn in
  let after =
    day_span days_after |> Ptime.add_span today |> Option.value_exn
  in
  traverse path is_vcf |> List.map ~f:extract
  |> List.fold ~init:[] ~f:List.append (* flatten *)
  |> List.fold ~init:[] ~f:(fun accum event ->
      let get_next_event = Icalendar.recur_events event in
      let rec aux accum =
        match get_next_event () with
        | Some new_event when Ptime.is_earlier (get_start new_event) ~than:after ->
          aux (List.cons new_event accum)
        | _ -> accum in
      let events = aux [event] in
      List.append accum events
    )
  |> List.filter ~f:(fun event ->
      let start = get_start event in
      Ptime.is_later start ~than:behind && Ptime.is_earlier start ~than:after)
  |> List.stable_sort ~compare:(fun event1 event2 ->
      Ptime.compare (get_start event1) (get_start event2))
  |> List.iter ~f:to_org

let command =
  Command.basic ~summary:"Summarize iCalendar files into Org format."
    Command.Let_syntax.(
      let%map_open path = anon ("path" %: string)
      and days_behind = anon ("days_behind" %: int)
      and days_after = anon ("days_after" %: int) in
      fun () -> discover path days_behind days_after)

let () = Command.run ~version:"1.0" command

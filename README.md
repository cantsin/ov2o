# Export calendars into org-mode

Given a list of calendars (in [icalendar](https://github.com/roburio/icalendar) format), output all events within a given timeframe to org format.

Written as an alternative to [ical2org.py](https://github.com/asoroa/ical2org.py), as I needed something that would handle calendars from multiple sources and had a stable sort (re-running the program on the same inputs will give the same ordering).

A nix derivation is given in `build.nix`.

## Example

Print out all events within the last two days and the next week:

    ./ov2o.exe /path/to/my-calendars/ 2 7

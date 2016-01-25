-module(rfc3339).

-export([parse/1]).
-export([format/1]).
-export([to_tuple/1]).
-export([to_map/1]).
-export_type([datetime/0, date/0, time/0, tz/0]).
-export_type([year/0, month/0, day/0]).
-export_type([hour/0, min/0, sec/0, usec/0]).
-export_type([tz_offset/0]).
-export_type([(error/0)]).

-type datetime() :: {date(), time(), tz()}.

-type date() :: {year(), month(), day()}.
-type year() :: 0..9999.
-type month() :: 0..12.
-type day() :: 0..31.

-type time() :: {hour(), min(), sec(), usec()}.
-type hour() :: 0..24.
-type min() :: 0..59.
-type sec() :: 0..60.
-type usec() :: 0..999999.

-type tz() :: tz_offset().
-type tz_offset() :: -1439..1439.

-type error() :: map().


-spec parse(binary()) -> {ok, datetime()} | {error, error()}.
parse(Bin) -> time_or_date(Bin, {undefined, undefined, undefined}).

-spec format(map() | datetime()) -> {ok, binary()} | {error, error()}.
format({{Year, Month, Day}, {Hour, Min, Sec, USec}, Offset}) ->
  DT = #{year => Year, month => Month, day => Day,
         hour => Hour, min => Min, sec => Sec, usec => USec,
         tz_offset => Offset},
  format(DT);
format(DT) ->
  Date = format_date(DT),
  Time = format_time(DT),
  format(Date, Time).

-spec to_tuple(binary()) -> {ok, datetime()} | {error, error()}.
to_tuple(Bin) -> parse(Bin).

-spec to_map(binary()) -> {ok, map()} | {error, error()}.
to_map(Bin) ->
  case parse(Bin) of
    {ok, {Date, Time, Offset}} ->
      mapify(Date, Time, Offset, #{});
    {error, Error} -> {error, Error}
  end.

mapify(undefined, Time, Offset, Result) -> mapify(Time, Offset, Result);
mapify({Year, Month, Day}, Time, Offset, Result) ->
  mapify(Time, Offset, maps:merge(Result, #{year => Year, month => Month, day => Day})).

mapify(undefined, _, Result) -> Result;
mapify({Hour, Min, Sec, undefined}, Offset, Result) ->
  mapify(Offset, maps:merge(Result, #{hour => Hour, min => Min, sec => Sec})); 
mapify({Hour, Min, Sec, USec}, Offset, Result) ->
  mapify(Offset, maps:merge(Result, #{hour => Hour, min => Min, sec => Sec, usec => USec})).

mapify(undefined, Result) -> Result;
mapify(Offset, Result) ->
  maps:merge(Result, #{tz_offset => Offset}).

time_or_date(<<H1, H2, $:, M1, M2, $:, S1, S2, Rest/binary>>, _Result) ->
  Hour = to_hour(H1, H2),
  Min = to_minute(M1, M2),
  Sec = to_second(S1, S2),
  usec_or_tz(Rest, {undefined, {Hour, Min, Sec, undefined}, undefined});
time_or_date(<<Y1, Y2, Y3, Y4, $-, M1, M2, $-, D1, D2, Rest/binary>>, _Result) ->
  Year = to_year(Y1, Y2, Y3, Y4),
  Month = to_month(M1, M2),
  Day = to_day(D1, D2, Year, Month),
  time_or_end(Rest, {{Year, Month, Day}, undefined, undefined});
time_or_date(_, _Result) ->
  {error, badarg}.


usec_or_tz(<<$., Rest/binary>>, Result) ->
  usec(Rest, Result, 0, 100000);
usec_or_tz(Rest, Result) -> tz(Rest, Result).

%% next two clauses burn off fractional seconds beyond microsecond precision
usec(<<X, Rest/binary>>, Result, undefined, undefined)
when X >= $0 andalso X =< $9 ->
  usec(Rest, Result, undefined, undefined);
usec(Bin, Result, undefined, undefined) ->
  tz(Bin, Result);
%% keep a running acc of usecs
usec(<<X, Rest/binary>>, Result, Acc, Multiplier)
when X >= $0 andalso X =< $9 ->
  try list_to_integer([X]) of
    N -> usec(Rest, Result, Acc + (N * Multiplier), Multiplier div 10)
  catch
    error:badarg -> {error, badusec}
  end;
%% not a digit, insert usecs into time and proceed to tz
usec(Bin, {Date, {Hour, Min, Sec, undefined}, undefined}, Acc, _) ->
  tz(Bin, {Date, {Hour, Min, Sec, Acc}, undefined});
usec(_, _, _, _) -> {error, badusec}.

tz(<<$+, H1, H2, $:, M1, M2>>, {Date, Time, undefined}) ->
  Hour = to_hour(H1, H2),
  Min = to_minute(M1, M2),
  {ok, {Date, Time, (Hour * 60) + Min}};
tz(<<$-, H1, H2, $:, M1, M2>>, {Date, Time, undefined}) ->
  Hour = to_hour(H1, H2),
  Min = to_minute(M1, M2),
  {ok, {Date, Time, (Hour * -60) - Min}};
tz(<<$Z>>, Result) ->
  {ok, Result};
tz(<<$z>>, Result) ->
  {ok, Result};
tz(_, _) -> {error, badtimezone}.

%% space
time_or_end(<<16#20, H1, H2, $:, M1, M2, $:, S1, S2, Rest/binary>>, {Date, undefined, undefined}) ->
  Hour = to_hour(H1, H2),
  Min = to_minute(M1, M2),
  Sec = to_second(S1, S2),
  usec_or_tz(Rest, {Date, {Hour, Min, Sec, undefined}, undefined});
time_or_end(<<$t, H1, H2, $:, M1, M2, $:, S1, S2, Rest/binary>>, {Date, undefined, undefined}) ->
  Hour = to_hour(H1, H2),
  Min = to_minute(M1, M2),
  Sec = to_second(S1, S2),
  usec_or_tz(Rest, {Date, {Hour, Min, Sec, undefined}, undefined});
time_or_end(<<$T, H1, H2, $:, M1, M2, $:, S1, S2, Rest/binary>>, {Date, undefined, undefined}) ->
  Hour = to_hour(H1, H2),
  Min = to_minute(M1, M2),
  Sec = to_second(S1, S2),
  usec_or_tz(Rest, {Date, {Hour, Min, Sec, undefined}, undefined});
time_or_end(<<>>, Result) -> {ok, Result};
time_or_end(_, _) -> {error, badtime}.

to_hour(H1, H2) ->
  try list_to_integer([H1, H2]) of
    X when X >= 0 andalso X =< 23 -> X;
    _ -> {error, badhour}
  catch
    error:badarg -> {error, badhour}
  end.

to_minute(M1, M2) ->
  try list_to_integer([M1, M2]) of
    X when X >= 0 andalso X =< 59 -> X;
    _ -> {error, badminute}
  catch
    error:badarg -> {error, badminute}
  end.

to_second(S1, S2) ->
  try list_to_integer([S1, S2]) of
    X when X >= 0 andalso X =< 60 -> X;
    _ -> {error, badsecond}
  catch
    error:badarg -> {error, badsecond}
  end.

to_year(Y1, Y2, Y3, Y4) ->
  try list_to_integer([Y1, Y2, Y3, Y4]) of
    X when X >= 0 andalso X =< 9999 -> X;
    _ -> {error, badyear}
  catch
    error:badarg -> {error, badyear}
  end.

to_month(M1, M2) ->
  try list_to_integer([M1, M2]) of
    X when X >= 1 andalso X =< 12 -> X;
    _ -> {error, badmonth}
  catch
    error:badarg -> {error, badmonth}
  end.

to_day(D1, D2, Year, Month) ->
  try list_to_integer([D1, D2]) of
    X when X >= 0 andalso X =< 28 -> X;
    X when X >= 29 andalso X =< 31 ->
      case day_in_month(Year, Month, X) of
        true -> X;
        false -> {error, badday}
      end;
    _ -> {error, badday}
  catch
    error:badarg -> {error, badday}
  end.

day_in_month({error, badyear}, _, _) -> {error, badyear};
day_in_month(_, {error, badmonth}, _) -> {error, badmonth};
day_in_month(Year, Month, Day) ->
  case Day of
    29 when Month == 2 -> ((Year rem 4 == 0) andalso not (Year rem 100 == 0)) orelse (Year rem 400 == 0);
    30 when Month == 2 -> false;
    31 when Month == 2; Month == 4; Month == 6; Month == 9; Month == 11 -> false;
    _ -> true
  end.

format_date(DT) ->
  Year = maps:get(year, DT, undefined),
  Month = maps:get(month, DT, undefined),
  Day = maps:get(day, DT, undefined),
  format_date(Year, Month, Day).

format_date(Y, M, D) when is_integer(Y), is_integer(M), is_integer(D) ->
  io_lib:format("~4.10.0B-~2.10.0B-~2.10.0B", [Y, M, D]);
format_date(undefined, undefined, undefined) -> {error, nodate};
format_date(nil, nil, nil) -> {error, nodate};
format_date(_, _, _) -> {error, baddate}.

format_time(DT) ->
  Hour = maps:get(hour, DT, undefined),
  Min = maps:get(min, DT, undefined),
  Sec = maps:get(sec, DT, undefined),
  USec = maps:get(usec, DT, undefined),
  Time = format_time(Hour, Min, Sec, USec),
  Offset = maps:get(tz_offset, DT, undefined),
  TZ = format_offset(Offset),
  format_time(Time, TZ).

format_time(H, M, S, undefined) when is_integer(H), is_integer(M), is_integer(S) ->
  io_lib:format("~2.10.0B:~2.10.0B:~2.10.0B", [H, M, S]);
format_time(H, M, S, nil) when is_integer(H), is_integer(M), is_integer(S) ->
  io_lib:format("~2.10.0B:~2.10.0B:~2.10.0B", [H, M, S]);
format_time(H, M, S, U) when is_integer(H), is_integer(M), is_integer(S), is_integer(U) ->
  SU = (S / 1) + (U / 1000000),
  io_lib:format("~2.10.0B:~2.10.0B:~9.6.0f", [H, M, SU]);
format_time(undefined, undefined, undefined, undefined) -> {error, notime};
format_time(nil, nil, nil, nil) -> {error, notime};
format_time(_, _, _, _) -> {error, badtime}.

format_offset(undefined) -> "Z";
format_offset(nil) -> "Z";
format_offset(0) -> "Z";
format_offset(M) when is_integer(M) ->
  Sign = case M >= 0 of true -> "+"; false -> "-" end,
  Hour = abs(M) div 60,
  Min = abs(M) rem 60,
  Sign ++ io_lib:format("~2.10.0B:~2.10.0B", [Hour, Min]).

format_time({error, Error}, _) -> {error, Error};
format_time(Time, TZ) -> [Time, TZ].

format({error, baddate}, _) -> {error, badarg};
format(_, {error, badtime}) -> {error, badtime};
format({error, nodate}, {error, notime}) -> {error, badarg};
format({error, nodate}, Time) -> unicode:characters_to_binary(Time);
format(Date, {error, notime}) -> unicode:characters_to_binary(Date);
format(Date, Time) -> unicode:characters_to_binary([Date, "T", Time]).
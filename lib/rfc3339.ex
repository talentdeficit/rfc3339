defmodule RFC3339 do
  defstruct year: nil, month: nil, day: nil,
            hour: nil, min: nil, sec: nil, usec: nil,
            tz_offset: nil 

  def parse(dt) do
    case :rfc3339.parse(dt) do
      {:ok, {date, time, tz}} ->
        dt = %RFC3339{}
        dt = insert_date(dt, date)
        dt = insert_time(dt, time)
        insert_tz(dt, tz)
      {:error, error} ->
        RFC3339.Error.from_erl(error)
    end
  end

  def format(dt), do: :rfc3339.format(dt)

  defp insert_date(dt, {year, month, day}) do
    %{ dt | :year => year, :month => month, :day => day }
  end
  defp insert_date(dt, :undefined), do: dt

  defp insert_time(dt, {hour, min, sec, :undefined}) do
    %{ dt | :hour => hour, :min => min, :sec => sec }
  end
  defp insert_time(dt, {hour, min, sec, usec}) do
    %{ dt | :hour => hour, :min => min, :sec => sec, :usec => usec }
  end
  defp insert_time(dt, :undefined), do: dt

  defp insert_tz(dt, :undefined), do: dt
  defp insert_tz(dt, offset), do: %{ dt | :tz_offset => offset }
end

defmodule RFC3339.Error do
  defstruct message: nil, reason: nil

  def from_erl(error) do
    %RFC3339.Error{message: error_to_message(error), reason: error}
  end
  
  defp error_to_message(_), do: "" 
end

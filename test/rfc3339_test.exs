defmodule RFC3339Test do
  use ExUnit.Case

  test "decode 0000-01-01" do
    assert %RFC3339{year: 0, month: 1, day: 1} == RFC3339.parse("0000-01-01")
  end

  test "decode 9999-12-31" do
    assert %RFC3339{year: 9999, month: 12, day: 31} == RFC3339.parse("9999-12-31")
  end

  test "decode 1584-03-04" do
    assert %RFC3339{year: 1584, month: 3, day: 4} == RFC3339.parse("1584-03-04")
  end

  test "decode 1900-01-01" do
    assert %RFC3339{year: 1900, month: 1, day: 1} == RFC3339.parse("1900-01-01")
  end
  
  test "decode 2016-01-24" do
    assert %RFC3339{year: 2016, month: 1, day: 24} == RFC3339.parse("2016-01-24")
  end

  test "decode 00:00:00Z" do
    assert %RFC3339{hour: 0, min: 0, sec: 0} == RFC3339.parse("00:00:00Z")
  end

  test "decode 23:59:60Z" do
    assert %RFC3339{hour: 23, min: 59, sec: 60} == RFC3339.parse("23:59:60Z")
  end

  test "decode 23:59:60.5Z" do
    assert %RFC3339{hour: 23, min: 59, sec: 60, usec: 500000} == RFC3339.parse("23:59:60.5Z")
  end

  test "decode 23:59:60.55Z" do
    assert %RFC3339{hour: 23, min: 59, sec: 60, usec: 550000} == RFC3339.parse("23:59:60.55Z")
  end

  test "decode 23:59:60.555555Z" do
    assert %RFC3339{hour: 23, min: 59, sec: 60, usec: 555555} == RFC3339.parse("23:59:60.555555Z")
  end

  test "decode 23:59:60.5555554Z" do
    assert %RFC3339{hour: 23, min: 59, sec: 60, usec: 555555} == RFC3339.parse("23:59:60.5555554Z")
  end

  test "decode 23:59:60.999999Z" do
    assert %RFC3339{hour: 23, min: 59, sec: 60, usec: 999999} == RFC3339.parse("23:59:60.999999Z")
  end

  test "decode 23:59:60.9999999Z" do
    assert %RFC3339{hour: 23, min: 59, sec: 60, usec: 999999} == RFC3339.parse("23:59:60.9999999Z")
  end

  test "decode 00:00:00+00:00" do
    assert %RFC3339{hour: 0, min: 0, sec: 0, tz_offset: 0} == RFC3339.parse("00:00:00+00:00")
  end

  test "decode 00:00:00-00:00" do
    assert %RFC3339{hour: 0, min: 0, sec: 0, tz_offset: 0} == RFC3339.parse("00:00:00-00:00")
  end

  test "decode 00:00:00+23:59" do
    assert %RFC3339{hour: 0, min: 0, sec: 0, tz_offset: 1439} == RFC3339.parse("00:00:00+23:59")
  end

  test "decode 23:59:60+00:00" do
    assert %RFC3339{hour: 23, min: 59, sec: 60, tz_offset: 0} == RFC3339.parse("23:59:60+00:00")
  end

  test "decode 23:59:60+23:59" do
    assert %RFC3339{hour: 23, min: 59, sec: 60, tz_offset: 1439} == RFC3339.parse("23:59:60+23:59")
  end

  test "decode 23:59:60-23:59" do
    assert %RFC3339{hour: 23, min: 59, sec: 60, tz_offset: -1439} == RFC3339.parse("23:59:60-23:59")
  end

  test "decode 1979-06-21T22:20:03Z" do
    assert %RFC3339{year: 1979, month: 6, day: 21, hour: 22, min: 20, sec: 3} == RFC3339.parse("1979-06-21T22:20:03Z")
  end

  test "decode 1979-06-21t22:20:03z" do
    assert %RFC3339{year: 1979, month: 6, day: 21, hour: 22, min: 20, sec: 3} == RFC3339.parse("1979-06-21t22:20:03z")
  end

  test "decode 1979-06-21 22:20:03Z" do
    assert %RFC3339{year: 1979, month: 6, day: 21, hour: 22, min: 20, sec: 3} == RFC3339.parse("1979-06-21 22:20:03Z")
  end

  test "decode 1979-06-21T22:20:03.9876543Z" do
    assert %RFC3339{year: 1979, month: 6, day: 21, hour: 22, min: 20, sec: 3, usec: 987654} == RFC3339.parse("1979-06-21T22:20:03.9876543Z")
  end

  test "decode 1979-06-21T22:20:03+02:00" do
    assert %RFC3339{year: 1979, month: 6, day: 21, hour: 22, min: 20, sec: 3, tz_offset: 120} == RFC3339.parse("1979-06-21T22:20:03+02:00")
  end

  test "decode 1979-06-21T22:20:03.9876543+02:00" do
    assert %RFC3339{year: 1979, month: 6, day: 21, hour: 22, min: 20, sec: 3, usec: 987654, tz_offset: 120} == RFC3339.parse("1979-06-21T22:20:03.9876543+02:00")
  end

  test "encode 1979-06-21" do
    assert "1979-06-21" == RFC3339.format(%RFC3339{year: 1979, month: 6, day: 21})
  end

  test "encode 12:12:12Z" do
    assert "12:12:12Z" == RFC3339.format(%RFC3339{hour: 12, min: 12, sec: 12})
  end

  test "encode 12:12:12.120000Z" do
    assert "12:12:12.120000Z" == RFC3339.format(%RFC3339{hour: 12, min: 12, sec: 12, usec: 120000})
  end

  test "encode 12:12:12.000012Z" do
    assert "12:12:12.000012Z" == RFC3339.format(%RFC3339{hour: 12, min: 12, sec: 12, usec: 12})
  end

  test "encode 12:12:12+12:12" do
    assert "12:12:12+12:12" == RFC3339.format(%RFC3339{hour: 12, min: 12, sec: 12, tz_offset: 732})
  end

  test "encode 12:12:12-12:12" do
    assert "12:12:12-12:12" == RFC3339.format(%RFC3339{hour: 12, min: 12, sec: 12, tz_offset: -732})
  end

  test "encode 1979-06-21T12:12:12Z" do
    assert "1979-06-21T12:12:12Z" == RFC3339.format(%RFC3339{year: 1979, month: 6, day: 21, hour: 12, min: 12, sec: 12})
  end

end

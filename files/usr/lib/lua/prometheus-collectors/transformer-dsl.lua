local proxy = require("datamodel")
local content_helper = require("web.content_helper")
local find, sub, format, floor = string.find, string.sub, string.format, math.floor
local content = {
  status = "sys.class.xdsl.@line0.LinkStatus",
  version = "rpc.xdsl.dslversion",
  dsl_linerate_up_max = "sys.class.xdsl.@line0.UpstreamMaxRate",
  dsl_linerate_down_max = "sys.class.xdsl.@line0.DownstreamMaxRate",
  dsl_linerate_up = "sys.class.xdsl.@line0.UpstreamCurrRate",
  dsl_linerate_down = "sys.class.xdsl.@line0.DownstreamCurrRate",
  dsl_margin_up = "sys.class.xdsl.@line0.UpstreamNoiseMargin",
  dsl_margin_down = "sys.class.xdsl.@line0.DownstreamNoiseMargin",
  dsl_attenuation_up = "sys.class.xdsl.@line0.UpstreamAttenuation",
  dsl_attenuation_down = "sys.class.xdsl.@line0.DownstreamAttenuation",
  dsl_power_up = "sys.class.xdsl.@line0.UpstreamPower",
  dsl_power_down = "sys.class.xdsl.@line0.DownstreamPower",
  dsl_type = "sys.class.xdsl.@line0.ModulationType",
  dsl_margin_SNRM_up = "sys.class.xdsl.@line0.UpstreamSNRMpb",
  dsl_margin_SNRM_down = "sys.class.xdsl.@line0.DownstreamSNRMpb",
  dslam_chipset = "rpc.xdslctl.DslamChipset",
  dslam_version = "rpc.xdslctl.DslamVersion",
  dslam_version_raw = "rpc.xdslctl.DslamVersionRaw",
  dsl_profile = "rpc.xdslctl.DslProfile",
  dsl_port = "rpc.xdslctl.DslamPort",
  dsl_serial = "rpc.xdslctl.DslamSerial",
  dsl_mode = "rpc.xdslctl.DslMode",
  uptime = "rpc.network.interface.@wan.uptime",
  dsl_fec_total_up = "sys.class.xdsl.@line0.UpstreamFECTotal",
  dsl_fec_curquarter_up = "sys.class.xdsl.@line0.UpstreamFECCurrentQuarter",
  dsl_fec_prevquarter_up = "sys.class.xdsl.@line0.UpstreamFECPreviousQuarter",
  dsl_fec_prevday_up = "sys.class.xdsl.@line0.UpstreamFECPreviousDay",
  dsl_fec_lastshowtime_up = "sys.class.xdsl.@line0.UpstreamFECLastShowtime",
  dsl_fec_sincesync_up = "sys.class.xdsl.@line0.UpstreamFECSinceSync",
  dsl_fec_currentday_up = "sys.class.xdsl.@line0.UpstreamFECCurrentDay",
  dsl_fec_total_down = "sys.class.xdsl.@line0.DownstreamFECTotal",
  dsl_fec_prevquarter_down = "sys.class.xdsl.@line0.DownstreamFECPreviousQuarter",
  dsl_fec_currentday_down = "sys.class.xdsl.@line0.DownstreamFECCurrentDay",
  dsl_fec_lastshowtime_down = "sys.class.xdsl.@line0.DownstreamFECLastShowtime",
  dsl_fec_curquarter_down = "sys.class.xdsl.@line0.DownstreamFECCurrentQuarter",
  dsl_fec_sincesync_down = "sys.class.xdsl.@line0.DownstreamFECSinceSync",
  dsl_fec_prevday_down = "sys.class.xdsl.@line0.DownstreamFECPreviousDay",
  dsl_los_total_up = "sys.class.xdsl.@line0.UpstreamLOSTotal",
  dsl_los_total_down = "sys.class.xdsl.@line0.DownstreamLOSTotal",
  dsl_uas_total_up = "sys.class.xdsl.@line0.UpstreamUASTotal",
  dsl_uas_total_down = "sys.class.xdsl.@line0.DownstreamUASTotal",
}

content_helper.getExactContent(content)

local function scrape()
  local dsl_line_attenuation = metric("dsl_line_attenuation_db", "gauge")
  local dsl_signal_attenuation = metric("dsl_signal_attenuation_db", "gauge")
  local dsl_snr = metric("dsl_signal_to_noise_margin_db", "gauge")
  local dsl_aggregated_transmit_power = metric("dsl_aggregated_transmit_power_db", "gauge")
  local dsl_latency = metric("dsl_latency_seconds", "gauge")
  local dsl_datarate = metric("dsl_datarate", "gauge")
  local dsl_max_datarate = metric("dsl_max_datarate", "gauge")
  local dsl_error_seconds_total = metric("dsl_error_seconds_total", "counter")
  local dsl_errors_total = metric("dsl_errors_total", "counter")

  local u = ubus.connect()
  local m = u:call("dsl", "metrics", {})

  -- dsl hardware/firmware information
  metric("dsl_info", "gauge", {
    dslam_chipset = content.dslam_chipset,
    dslam_version = content.dslam_version,
    dslam_version_raw = content.dslam_version_raw,
    dslam_port = content.dsl_port,
    dslam_serial = content.dsl_serial,
  }, 1)

  -- dsl line settings information
  metric("dsl_line_info", "gauge", {
    dsl_mode = content.dsl_mode,
    dsl_profile = content.dsl_profile,
    dsl_status = content.status,
    dsl_version = content.version,
    dsl_type = content.dsl_type,
  }, 1)

  local dsl_up
  if content.status == "Showtime" then
    dsl_up = 1
  else
    dsl_up = 0
  end

  metric("dsl_up", "gauge", {
    detail = content.status,
  }, dsl_up)

  -- dsl line status data
  metric("dsl_uptime_seconds", "gauge", {}, content.uptime)

  -- dsl db measurements
  ct = 0
  for v in string.gmatch(content.dsl_attenuation_down, "[^,]+") do
    dsl_line_attenuation({direction="down", value="D"..ct}, tonumber(v))
    ct = ct +1
  end
  ct = 0
  for v in string.gmatch(content.dsl_attenuation_up, "[^,]+") do
    dsl_line_attenuation({direction="up", value="U"..ct}, tonumber(v))
    ct = ct +1
  end

  ct = 0
  for v in string.gmatch(content.dsl_margin_SNRM_up, "[^,]+") do
    dsl_snr({direction="up", value="U"..ct}, tonumber(v))
    ct = ct +1
  end

  ct = 0
  for v in string.gmatch(content.dsl_margin_SNRM_down, "[^,]+") do
    dsl_snr({direction="down", value="D"..ct}, tonumber(v))
    ct = ct +1
  end
  ct = 0
  for v in string.gmatch(content.dsl_power_up, "[^,]+") do
    dsl_aggregated_transmit_power({direction="up", value="U"..ct}, tonumber(v))
    ct = ct +1
  end
  ct = 0
  for v in string.gmatch(content.dsl_power_down, "[^,]+") do
    dsl_aggregated_transmit_power({direction="down", value="D"..ct}, tonumber(v))
    ct = ct +1
  end
  ct = 0
  for v in string.gmatch(content.dsl_linerate_down, "[^,]+") do
    dsl_datarate({direction="down", value="D"..ct}, tonumber(v))
    ct = ct +1
  end
  ct = 0
  for v in string.gmatch(content.dsl_linerate_up, "[^,]+") do
    dsl_datarate({direction="up", value="U"..ct}, tonumber(v))
    ct = ct +1
  end
  ct = 0
  for v in string.gmatch(content.dsl_linerate_down_max, "[^,]+") do
    dsl_max_datarate({direction="down", value="D"..ct}, tonumber(v))
    ct = ct +1
  end
  ct = 0
  for v in string.gmatch(content.dsl_linerate_up_max, "[^,]+") do
    dsl_max_datarate({direction="up", value="U"..ct}, tonumber(v))
    ct = ct +1
  end

  dsl_error_seconds_total({err="FEC", loc="up", type="total"}, content.dsl_fec_total_up)
  dsl_error_seconds_total({err="FEC", loc="down", type="total"}, content.dsl_fec_total_down)
  dsl_error_seconds_total({err="FEC", loc="up", type="curquarter"}, content.dsl_fec_curquarter_up)
  dsl_error_seconds_total({err="FEC", loc="down", type="curquarter"}, content.dsl_fec_curquarter_down)
  dsl_error_seconds_total({err="FEC", loc="up", type="prevquarter"}, content.dsl_fec_prevquarter_up)
  dsl_error_seconds_total({err="FEC", loc="down", type="prevquarter"}, content.dsl_fec_prevquarter_down)
  dsl_error_seconds_total({err="FEC", loc="up", type="prevday"}, content.dsl_fec_prevday_up)
  dsl_error_seconds_total({err="FEC", loc="down", type="prevday"}, content.dsl_fec_prevday_down)
  dsl_error_seconds_total({err="FEC", loc="up", type="lastshowtime"}, content.dsl_fec_lastshowtime_up)
  dsl_error_seconds_total({err="FEC", loc="down", type="lastshowtime"}, content.dsl_fec_lastshowtime_down)
  dsl_error_seconds_total({err="FEC", loc="up", type="sincesync"}, content.dsl_fec_sincesync_up)
  dsl_error_seconds_total({err="FEC", loc="down", type="sincesync"}, content.dsl_fec_sincesync_down)
  dsl_error_seconds_total({err="FEC", loc="up", type="currentday"}, content.dsl_fec_currentday_up)
  dsl_error_seconds_total({err="FEC", loc="down", type="currentday"}, content.dsl_fec_currentday_down)

  dsl_error_seconds_total({err="LOS- Loss of Signal", loc="up", type="total"}, content.dsl_los_total_up)
  dsl_error_seconds_total({err="LOS- Loss of Signal", loc="down", type="total"}, content.dsl_los_total_down)

  dsl_error_seconds_total({err="UAS- Signal Unavailable", loc="up", type="total"}, content.dsl_los_total_up)
  dsl_error_seconds_total({err="UAS- Signal Unavailable", loc="down", type="total"}, content.dsl_los_total_down)

--[[
  -- dsl db measurements
  dsl_signal_attenuation({direction="down"}, m.downstream.satn)
  dsl_signal_attenuation({direction="up"}, m.upstream.satn)

  -- dsl performance data
  if m.downstream.interleave_delay ~= nil then
    dsl_latency({direction="down"}, m.downstream.interleave_delay / 1000000)
    dsl_latency({direction="up"}, m.upstream.interleave_delay / 1000000)
  end

  -- dsl errors
  dsl_error_seconds_total({err="forward error correction", loc="near"}, m.errors.near.fecs)
  dsl_error_seconds_total({err="forward error correction", loc="far"}, m.errors.far.fecs)
  dsl_error_seconds_total({err="errored", loc="near"}, m.errors.near.es)
  dsl_error_seconds_total({err="errored", loc="far"}, m.errors.far.es)
  dsl_error_seconds_total({err="severely errored", loc="near"}, m.errors.near.ses)
  dsl_error_seconds_total({err="severely errored", loc="far"}, m.errors.far.ses)
  dsl_error_seconds_total({err="loss of signal", loc="near"}, m.errors.near.loss)
  dsl_error_seconds_total({err="loss of signal", loc="far"}, m.errors.far.loss)
  dsl_error_seconds_total({err="unavailable", loc="near"}, m.errors.near.uas)
  dsl_error_seconds_total({err="unavailable", loc="far"}, m.errors.far.uas)
  dsl_errors_total({err="header error code error", loc="near"}, m.errors.near.hec)
  dsl_errors_total({err="header error code error", loc="far"}, m.errors.far.hec)
  dsl_errors_total({err="non pre-emptive crc error", loc="near"}, m.errors.near.crc_p)
  dsl_errors_total({err="non pre-emptive crc error", loc="far"}, m.errors.far.crc_p)
  dsl_errors_total({err="pre-emptive crc error", loc="near"}, m.errors.near.crcp_p)
  dsl_errors_total({err="pre-emptive crc error", loc="far"}, m.errors.far.crcp_p)
]]
end

return { scrape = scrape }

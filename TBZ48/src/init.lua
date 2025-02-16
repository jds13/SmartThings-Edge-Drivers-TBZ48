
local log = require "log"

local capabilities = require "st.capabilities"
local ZwaveDriver = require "st.zwave.driver"
local defaults = require "st.zwave.defaults"
local cc = require "st.zwave.CommandClass"
local ThermostatFanMode = (require "st.zwave.CommandClass.ThermostatFanMode")({version=3})
local ThermostatMode = (require "st.zwave.CommandClass.ThermostatMode")({version=2})
local ThermostatOperatingState = (require "st.zwave.CommandClass.ThermostatOperatingState")({ version = 1 })
local ThermostatSetpoint = (require "st.zwave.CommandClass.ThermostatSetpoint")({version=1})
local Configuration = (require "st.zwave.CommandClass.Configuration")({version=1})
local constants = require "st.zwave.constants"
local utils = require "st.utils"


local function device_added(driver, device)
  if device:supports_capability_by_id(capabilities.thermostatMode.ID) and
    device:is_cc_supported(cc.THERMOSTAT_MODE) then
    device:send(ThermostatMode:SupportedGet({}))
  end
  if device:supports_capability_by_id(capabilities.thermostatFanMode.ID) and
    device:is_cc_supported(cc.THERMOSTAT_FAN_MODE) then
    device:send(ThermostatFanMode:SupportedGet({}))
  end
  if device:supports_capability_by_id(capabilities.thermostatOperatingState.ID) then
    --- factory default is 8223 = 0x201f. 0x0040 is the operating state report enable flag.
    device:send(Configuration:Set({ parameter_number = 23, size = 2, configuration_value = 0x205f }))
    local tstate = ThermostatOperatingState:Get({})
    device:send(tstate)
  end
  device:refresh()
end

local function convert_to_device_temp(command_temp, device_scale)
  -- under 40, assume celsius
  if (command_temp < 40 and device_scale == ThermostatSetpoint.scale.FAHRENHEIT) then
    command_temp = utils.c_to_f(command_temp)
  elseif (command_temp >= 40 and (device_scale == ThermostatSetpoint.scale.CELSIUS or device_scale == nil)) then
    command_temp = utils.f_to_c(command_temp)
  end
  return command_temp
end

local function set_setpoint_factory(setpoint_type)
  return function(driver, device, command)
    local scale = device:get_field(constants.TEMPERATURE_SCALE)
    local value = convert_to_device_temp(command.args.setpoint, scale)

    -- Zwave thermostat devices expect to get fractional values as an integer value
    -- with a provided precision such that the temp is value * 10^(-precision)
    -- See section 2.2.113.2 of the Zwave Specification for more info
    -- This is a temporary workaround for the Aeotec Thermostat device while
    -- more permanent fixes are added to scripting-engine
    local set
    if value % 1 == 0.5 then
      set = ThermostatSetpoint:Set({
        setpoint_type = setpoint_type,
        scale = scale,
        value = value,
        precision = 1,
        size = 2
      })
    else
      set = ThermostatSetpoint:Set({
        setpoint_type = setpoint_type,
        scale = scale,
        value = value
      })
    end
    device:send_to_component(set, command.component)

    local follow_up_poll = function()
      device:send_to_component(ThermostatSetpoint:Get({setpoint_type = setpoint_type}), command.component)
    end

    device.thread:call_with_delay(1, follow_up_poll)
  end
end

local function hOperatingState()
  return function(driver, device, command)
    --- thermostatOperatingStates:
    ---    0x00 - idle
    ---    0x01 - heating
    ---    0x02 - cooling
    ---    0x03 - fan only
    ---    0x04 - pending heat
    ---    0x05 - pending cool
    ---    0x06 - vent economy
    ---    0x07 - aux heat
    ---    0x08 - stage 2 heat
    ---    0x09 - stage 2 cool
    ---    0x0A - stage 2 aux heat
    ---    0x0B - stage 3 aux heat
    local tstate = ThermostatOperatingState:Get({})
    device:send(tstate)
    device:emit_event(capabilities.thermostatOperatingState.thermostatOperatingState(tstate))
    end
end

local driver_template = {
  supported_capabilities = {
    capabilities.temperatureAlarm,
    capabilities.temperatureMeasurement,
    capabilities.thermostatHeatingSetpoint,
    capabilities.thermostatCoolingSetpoint,
    capabilities.thermostatOperatingState,
    capabilities.thermostatMode,
    capabilities.thermostatFanMode,
    capabilities.relativeHumidityMeasurement,
    capabilities.battery,
    capabilities.powerMeter,
    capabilities.energyMeter
    },
  capability_handlers = {
    [capabilities.thermostatCoolingSetpoint.ID] = {
      [capabilities.thermostatCoolingSetpoint.commands.setCoolingSetpoint.NAME] = set_setpoint_factory(ThermostatSetpoint.setpoint_type.COOLING_1)
      },
    [capabilities.thermostatHeatingSetpoint.ID] = {
      [capabilities.thermostatHeatingSetpoint.commands.setHeatingSetpoint.NAME] = set_setpoint_factory(ThermostatSetpoint.setpoint_type.HEATING_1)
      },
    },
  lifecycle_handlers = {
    added = device_added
    }
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
local thermostat = ZwaveDriver("zwave_thermostat_TBZ48", driver_template)
thermostat:run()

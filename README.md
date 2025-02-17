# SmartThings-Edge-Drivers
SmartThings Edge Driver for the Nortek / GoControl / Linear TBZ48L Z-Wave Thermostat

This device driver tracks activates the thermostat Operating State triggers for your automations. Use these to alert you to your HVAC system operation, or manage other automations that might, for example, track HVAC system time and alert you when a filter needs replacing.

The states are:
    0x00 - Idle
    0x01 - Heating
    0x02 - Cooling
    0x03 - Fan Only
    0x04 - Pending Heat
    0x05 - Pending Cool
    0x06 - Vent Economy
    0x07 - Aux Heat
    0x08 - Stage 2 Heat
    0x09 - Stage 2 Cool
    0x0A - Stage 2 Aux Heat
    0x0B - Stage 3 Aux Heat

Then TBZ48 sends "Heating" when it turns on heat signal (Rh wire), "Pending Heat" when it turns heat off, and "Idle" approxmiately one minute after "Pending Heat."

By default, the TBZ48L thermostat disables thermostatOperatingState messages. This driver initializes Parameter 23 to turn on this feature.

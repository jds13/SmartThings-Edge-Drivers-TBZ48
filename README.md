# SmartThings-Edge-Drivers
<h2>SmartThings Edge Driver for the Nortek / GoControl / Linear TBZ48L Z-Wave Thermostat</h2>
<p>This device driver tracks activates the thermostat Operating State triggers for your automations. Use these to alert you to your HVAC system operation, or manage other automations that might, for example, track HVAC system time and alert you when a filter needs replacing.</p>

<p>The states are:<ul>
<li>    0x00 - Idle
<li>    0x01 - Heating
<li>    0x02 - Cooling
<li>    0x03 - Fan Only
<li>    0x04 - Pending Heat
<li>    0x05 - Pending Cool
<li>    0x06 - Vent Economy
<li>    0x07 - Aux Heat
<li>    0x08 - Stage 2 Heat
<li>    0x09 - Stage 2 Cool
<li>    0x0A - Stage 2 Aux Heat
<li>    0x0B - Stage 3 Aux Heat
</ul>
<p>The TBZ48 sends "Heating" when it turns on heat signal (Rh wire), "Pending Heat" when it turns heat off, and "Idle" approxmiately one minute after "Pending Heat."</p>

<p>By default, the TBZ48L thermostat disables thermostatOperatingState messages. This driver initializes Parameter 23 to turn on this feature.</p>

<p>TBZ48 Z-Wave configuration parameters are described <a href="https://manuals-backend.z-wave.info/make.php?lang=en&sku=GC-TBZ48L&cert=ZC10-17055590">here</a></p>

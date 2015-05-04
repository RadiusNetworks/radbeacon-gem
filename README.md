<img src="http://i.imgur.com/gI6paLj.jpg" style="float:left" height="200">

# What's all this then?

A ruby gem that provides RadBeacon scanning and configuring capabilities on a linux machine.  Currently the only supported beacon type is RadBeacon USB.  

# Scanning

The `Radbeacon::Scanner` class has a `scan` method that returns an array of configurable RadBeacons (in the form of `Radbeacon::Usb` objects).  The duration of a scan (default = 5 seconds) is an attribute that can be set during initialization.  

```
scanner = Radbeacon::Scanner.new(10)
radbeacons = scanner.scan
```

#### Scan Options

An (optional) `options` hash is available as an attribute on the `Scanner` class.  Below are the following options that can be used:

- `:filter_mac` - Specify an array of MAC addresses that the scanner will filter for when doing a scan

  ```
  options[:filter_mac] = ["11:22:33:44:55:66", "55:66:77:88:99:00"]
  ```

- `:enable_hcitool_duration` - Use the custom hcitool-duration binary that adds a duration option to the `hcitool lescan` command.  To use this you must copy the new hcitool binary over the standard one (located at `/usr/bin/hcitool` on the ZBOX for example).

  ```
  options[:enable_hcitool_duration] = true
  ```

#Configuring

All identifiers and other parameters are attributes on the `Radbeacon::Usb` class:

- `dev_name`
- `uuid`
- `major`
- `minor`
- `power`
- `tx_power`
- `adv_rate`
- `beacon_type`

To make a config change, simply assign one of these attributes to the desired value and call the `save()` method with the beacon's PIN (as a string).

```
radbeacon.save(pin)
```

For example:

```
radbeacon.dev_name = "Test Beacon"
radbeacon.uuid = "2F234454-CF6D-4A0F-ADF2-F4911BA9ABCD"
radbeacon.major = 1
radbeacon.minor = 1
radbeacon.power = -66
radbeacon.tx_power = 3
radbeacon.adv_rate = 10
radbeacon.beacon_type = "dual"
radbeacon.save('0000')
```

# Other Actions

All other RadBeacon actions are available as well

##### Change PIN
```
radbeacon.change_pin(new_pin, old_pin)
```

##### Factory Reset
```
radbeacon.factory_reset(pin)
```

##### Boot to DFU
```
radbeacon.boot_to_dfu(pin)
```

##### Lock
```
radbeacon.lock(pin)
```

# Dependencies

BlueZ (Linux Bluetooth stack) is required to scan for and communicate with RadBeacons via Bluetooth.  Specifically, the `hcitool` and `gatttool` commands.

{ lib
, writeShellApplication
, util-linux
, firmware
}:

writeShellApplication {
  name = "zmk-uf2-flash";

  runtimeInputs = [
    util-linux
  ];

  text = ''
    available() {
      lsblk -Sno path,model | grep -F 'nRF UF2' | cut -d' ' -f1
    }

    mounted() {
      findmnt "$device" -no target
    }

    flash=("$@")
    parts=(${toString firmware.parts or ""})

    if [ "''${#flash[@]}" -eq 0 ]; then
      if [ "''${#parts[@]}" -eq 0 ]; then
        flash=("")
      else
        flash=("''${parts[@]}")
      fi
    else
      for part in "''${flash[@]}"; do
        if ! printf '%s\0' "''${parts[@]}" | grep -Fxqz -- "$part"; then
          echo "The '$part' part does not exist in the firmware '"'${firmware.name}'"'"
          exit 1
        fi
      done
    fi

    for part in "''${flash[@]}"; do
      echo -n "Double tap reset and plug in$([ -n "$part" ] && echo " the '$part' part of") the keyboard via USB"
      while ! device="$(available)"; do
        echo -n .
        sleep 3
      done
      echo

      sleep 1

      mountpoint="$(mounted)"
      if [ -z "$mountpoint" ]; then
        echo -n "Please mount the mass storage device at $device so that the firmware file can be copied"
        while ! mountpoint="$(mounted)"; do
          echo -n .
          sleep 3
        done
      fi
      echo

      cp ${firmware}/*"$([ -n "$part" ] && ehco "_$part")".uf2
    done
  '';

  meta = with lib; {
    description = "ZMK UF2 firmware flasher";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ lilyinstarlight ];
  };
}

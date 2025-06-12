{
  activate_multipath: {
    name: 'activate multipath',
    content: |||
      #!/bin/bash
      if ! systemctl status multpathd ; then
        echo 'Activating multipath'
        systemctl start multipathd.socket
        systemctl start multipathd
      fi
    |||,
  },
  wipe_filesystem: {
    name: 'wipefs',
    content: |||
      #!/usr/bin/env bash
      for i in `lsblk -n -l -o NAME -d -e 7,11,254`
          do wipefs -af /dev/$i
          sleep 1
          sync
      done
    |||,
  },
  disable_questions: {
    name: 'disable questions',
    content: |||
      #!/usr/bin/env bash
      agama questions mode non-interactive
    |||,
  },
  configure_zypp_backend: {
    name: 'configure-zypp-backend-env.sh',
    content: |||
      #!/usr/bin/env bash

      # Set environment variable for the Agama service
      # This ensures libzypp picks up the setting regardless of config file timing
      echo 'ZYPP_SINGLE_RPMTRANS=1' >> /etc/environment

      # Also set it for the current session
      export ZYPP_SINGLE_RPMTRANS=1

      # Create a systemd environment file for Agama services
      mkdir -p /etc/systemd/system/agama.service.d
      echo '[Service]' > /etc/systemd/system/agama.service.d/zypp-config.conf
      echo 'Environment="ZYPP_SINGLE_RPMTRANS=1"' >> /etc/systemd/system/agama.service.d/zypp-config.conf
      echo 'Configured ZYPP_SINGLE_RPMTRANS=1 via environment variables'
    |||,
  },
}

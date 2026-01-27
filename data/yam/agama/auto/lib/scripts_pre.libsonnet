{
  wipe_filesystem: {
    name: 'wipefs',
    content: |||
      #!/usr/bin/env bash
      for i in `lsblk -n -l -o NAME -d -e 7,11,254`
          do wipefs -af /dev/$i
          sleep 1
          sync
      done
    |||
  },
  disable_questions: {
    name: 'disable questions',
    content: |||
      #!/usr/bin/env bash
      agama questions mode non-interactive
    |||
  },
  create_iscsi_initiator: {
    name: 'create iscsi initiator',
    content: |||
      #!/usr/bin/env bash
      echo "iqn.1996-04.de.suse:01:972154f2547d" > /etc/iscsi/initiatorname.iscsi
    |||
  },
}

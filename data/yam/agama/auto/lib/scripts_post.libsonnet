{
  enable_root_login: {
    name: 'enable root login',
    chroot: true,
    content: |||
      #!/usr/bin/env bash
      echo 'PermitRootLogin yes' > /etc/ssh/sshd_config.d/root.conf
    |||
  },
  add_serial_console_hvc1: {
    name: 'add serial console hvc1 for ppc64le',
    chroot: true,
    content: |||
      #!/usr/bin/env bash
      systemctl enable serial-getty@hvc1
    |||
  },
  set_grub_timeout: {
  "name": "set grub timeout to -1",
   chroot: true,
   content: |||
     #!/usr/bin/env bash
     grub2-editenv - set timeout=-1
   |||
},
}

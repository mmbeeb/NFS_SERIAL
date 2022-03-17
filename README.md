# NFS_SERIAL

My attempt at creating a Network Filing System (NFS 3.60) which uses the RS423 serial port, rather than Econet.

Beeb needs to be connected to a machine running 'spaun'.

*****

16/03/22 update

There is now a Sideways RAM version which no longer claims static or private workspace.

A faster CRC calculation allows increased data rates.

*****

Assembly
--------

To assemble use BeebAsm 1.09:

Sideways RAM version:

beebasm -i nfs_swram.asm

ROM version

beebasm -i nfs_rom.asm

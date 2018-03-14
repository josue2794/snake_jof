# Snake - Bootloader
Snake game made in assembly x86. Also bootable.
Made by:
* Fabian Astorga Cerdas
* Javier Sancho Marin
* Oscar Ulate Alpizar

### Compilation
To compile the source code, go to the source directory and then insert the following command:

* $ make

To umount the destination device, insert the following command: 

* $ sudo umount /dev/sdb

You can emulate the program if you want to test it. Make sure you have Qemu installed. Insert the following command:

* $ make emul

To format the destination device in fat32 and place the image file generated to boot device, insert the following command:

* $ make exec path=/dev/sdb

Make sure the path inserted is the correct device directory.

To make a clean, insert the following command:

* $ make clean

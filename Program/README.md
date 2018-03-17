# Snake - Bootloader
Snake game made in assembly x86. Also bootable.
Made by: 
* Fabián Astorga Cerdas
* Javier Sancho Marín
* Óscar Ulate Alpízar

### Compilation
To compile, execute the following command:

* $ sudo make 

To 'burn' the iso file into the USB, execute the following command:

* $ sudo make usb DIR=/dev/sdX

The 'X' on the USB path may be changed with a correct letter on the system. Try typing on terminal to get the USB drive path:

* $ sudo fdisk -l 

Make sure the path inserted is the correct device directory.

You can emulate the program if you want to test it. Make sure you have Qemu installed. Insert the following command: 

* $ sudo make emul

To make a clean, insert the following command: 

* $ make clean 

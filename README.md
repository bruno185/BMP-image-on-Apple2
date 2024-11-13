
# Apple II : Display a BMP image file using Graphics Primitives (in Mouse Graphics Toolkit) and Merlin32 syntax

Here's a program for Apple II.
It draws a BMP image (PC format) on the DHGR screen

It's written in assembler (Merlin32) and uses the "Graphics Primitives" library included in Apple's "Mouse Graphics Tool Kit". The source files are fully commented, for a clear understanding of the code.

## Use
This archive contains a ProDOS disk image (asmdemo.po) to be used it your favourite Apple II emulator or your Apple II.
* Start your Apple II or emulator with the "asmdemo.po" disk in S1D1
* The startup basic program will launch the demo program.

For amazing graphical effects, I suggest running the program on an emulator like AppleWin, at maximum speed.

## Requirements to compile and run

Here is my configuration:

* Visual Studio Code with 2 extensions :

-> [Merlin32 : 6502 code hightliting](marketplace.visualstudio.com/items?itemName=olivier-guinart.merlin32)

-> [Code-runner :  running batch file with right-clic.](marketplace.visualstudio.com/items?itemName=formulahendry.code-runner)

* [Merlin32 cross compiler](brutaldeluxe.fr/products/crossdevtools/merlin)

* [Applewin : Apple IIe emulator](github.com/AppleWin/AppleWin)

* [Applecommander ; disk image utility](applecommander.sourceforge.net)

* [Ciderpress ; disk image utility](a2ciderpress.com)

Compilation notes :

DoMerlin.bat puts it all together. If you want to compile yourself, you will have to adapt the path to the Merlin32 directory, to Applewin and to Applecommander in DoMerlin.bat file.

DoMerlin.bat is to be placed in project directory.
It compiles source (*.s) with Merlin32, copy 6502 binary to a disk image (containg ProDOS), and launch Applewin with this disk in S6,D1.


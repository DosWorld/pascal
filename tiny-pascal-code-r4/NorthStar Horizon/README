  Chung Yuen Tiny Pascal from BYTE 1978

All the relevant files for use with the Chung Yuen Tiny Pascal Compiler
and runtime 8080 code are included on the North Star DOS floppy image,
"TINYPASCAL.NSI". The .ASM sourcecode for the 8080 runtime is supplied
separately.

The version of NS DOS on the disk-image is set at the original standard
RAM address of 2000H, leaving the area of RAM 0000-1FFFH free for the
opcodes and the runtime to be placed there, as occurred with the
single-density North Star DOS used originally.

These addresses could be changed by adjusting the BASIC programs and by
assembling the runtime code to be placed elsewhere.


All of the files are also included as separate files, in case you don't
have a suitable NS DOS emulator, either Dave Dunfield's one for MSDOS
or mine at itelsoft.com.au for Linux.


North Star DOS disk-image "TINYPASCAL.NSI" files:

TINYPASC    0    8 D   0             Disk Label 
DOS         4   12 D   0             North Star DOS 5.2DQ
BASIC      10   54 D   1 2D00        North Star BASIC
CF         37    6 D   1 2D00        NSDOS 'copy file' program
TXT2DATA   40   10 D   2             Text to BASIC DATA converter
READDATA   45    6 D   2             Reads any BASIC DATA file
PASCOMP    48   58 D   2             Chung Yuen Pascal Compiler
PASTRANS   77   24 D   2             C-Y opcode to 8080 translator
PASRUN1A   89    6 D   1 1A00        8080 runtime code at 1A00H
PINT.TXT   92   22 D   3             Pascal Interpreter source (Text)
PINT.PAS  103   20 D   3             Pascal Interpreter source (Strings)
PINTERP   113   24 D   1 C000        Compiled Interpreter in 8080 code
HANOITXT  125    4 D   3             Towers of Hanoi source (Text)
HANOIPAS  127    4 D   3             Towers of Hanoi source (Strings) 
HANOI     129    2 D   1 C000        Compiled Towers of Hanoi in 8080

--

Why won't the compiler read my pascal source code text?

That's because the compiler is line oriented. BUT each line is
read as a North Star BASIC string, rather than a line of text, and
so must be in North Star BASIC String Format.

Use the TXT2DATA program (in BASIC) to convert your text source
code to a series of strings for PASCOMP.

--

Can I use lower-case variables, etc?

The original source for PASCOMP was restricted to upper-case only. I have
made a slight adjustment which allows lower-case variables as well.

---

Why can't I seem to get success by putting my 8080 runtime elsewhere in RAM?

The addresses where the translator program, PASTRANS, calls the various
opcode runtimes are 'hardcoded' in the PASTRANS program in BASIC lines
82-102. These values will need changing if you alter the RAM location of
the 8080 runtime code.



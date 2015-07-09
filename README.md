# blastplotter

blastplotter is a tool to quickly visualize e-value and percent ID of blast output.
Currently accepted input formats are:
	Command line:	outfmt 6
	Web Blast:	Hit Table(text)

Dependancies:
	perl
	R
	ggplot2 (R-package)
	gridExtra (R-package)

Usage:
	perl blastplotter.pl example/TX4SESG9015-Alignment.txt

If running the example attached, a file example/TX4SESG9015-Alignment.png should be generated.  If not, ensure that both R package dependancies are installed.


Note:  E-Score of n is equivalent to e-value of 1e-n

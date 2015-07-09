#!/bin/env perl

use strict;
use warnings;

my $ifn = shift;
my $ofn = $ifn;
$ofn =~ s/^(.+)\..+$/$1\.blpl.tsv/;
my %h = ();
open my $ifh, '<', $ifn or die $!;
my $ncbi = 0;

## Parse blast
while(<$ifh>){
	chomp;
	$ncbi = 1 if($_ =~ m/^# RID:/);  ## Flag for Hit Table(Text)
	next if($_ =~ m/^#/); ## Ignore comments
	next if($_ =~ m/^(\s+)?$/); ## Ignore blank lines
	my ($query, $hit, $pctpos, $pctid, $alen, $mismatch, $gapopen, $qstart, $qend, $sstart, $send, $evalue, $bitscore) = (undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef);
	if($ncbi == 0){
		($query, $hit, $pctid, $alen, $mismatch, $gapopen, $qstart, $qend, $sstart, $send, $evalue, $bitscore) = split(/\t/, $_);
	}else{
		($query, $hit, $pctid, $pctpos, $alen, $mismatch, $gapopen, $qstart, $qend, $sstart, $send, $evalue, $bitscore) = split(/\t/, $_);
	}
	## Convert evalue to escore
	my $escore = 0;
	if($evalue == 0){
		$escore = 200;
	}elsif($evalue =~ m/^([\d\.]+)e-(\d+)$/i){
		$escore = $2 . '.' . int($1);
	}
	## Save best escore to hash
	if(exists $h{$hit}){
		if($h{$hit}{'escore'} > $escore){
			next;
		}
	}
	$h{$hit} = {
		'escore'	=> $escore,
		'pid'		=> $pctid,
	};
}
close $ifh;

## Dump best hits to tsv
open my $ofh, '>', $ofn or die $!;
print $ofh join("\t", "Hit", "Type", "Score") . "\n";
foreach(keys %h){
	print $ofh join("\t", $_, 'E', $h{$_}{'escore'}) . "\n" . join("\t", $_, 'P', $h{$_}{'pid'}) . "\n";
}
close $ofh;
my $png = $ofn;
$png =~ s/\.blpl\.tsv$/.png/;

## Write R-Code
open my $r, '>', 'tmp.R' or die $!;
# no need to setwd
print $r "data <- read.table(\"$ofn\", header=TRUE, sep=\"\\t\")\n";
print $r 'data$Score <- as.numeric(data$Score)' . "\n";
print $r "e <- subset(data, Type==\"E\")\n";
print $r "p <- subset(data, Type==\"P\")\n";
print $r 'e$Rank <- rank(e$Score)/length(e$Score)' . "\n";
print $r 'p$Rank <- rank(p$Score)/length(p$Score)' . "\n";
print $r "library(ggplot2)\n";
print $r 'eplot <- ggplot(e, aes(Rank, Score)) + geom_point(color="deepskyblue3", size=4) + geom_line(color="deepskyblue3", size=1) + ggtitle("E-Score") + labs(y="Score")' . "\n";
print $r 'pplot <- ggplot(p, aes(Rank, Score)) + geom_point(color="palegreen3", size=4) + geom_line(color="palegreen3", size=1) + ggtitle("Percent ID") + labs(y="Score")' . "\n";
print $r "library(gridExtra)\n";
print $r "g <- arrangeGrob(eplot, pplot, ncol=2)\n";
print $r "ggsave(file=\"$png\", g, dpi=300, height=5, width=10)\n";
close $r;

## Run R
system("R CMD BATCH tmp.R");

## Cleanup
system("rm tmp.R*");
system("rm Rplots.pdf") if(-e 'Rplots.pdf');
system("rm $ofn");

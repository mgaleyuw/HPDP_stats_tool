# HPDP stats

Quick visualization of haplotagging and depth of sequencing success for Oxford Nanopore sequencing.

Depth of coverage, number of unique phaseblocks, and proportion of haplotagged reads are calculated for named regions provided in a bedfile or as a region, at a user provided interval (1kb default). Output can be summarized per bedfile region provided, or full interval output can be preserved for plotting.


### Requirements:

Rust version 1.72.1, samtools >= 1.17

Binaries of rust scripts are provided in /bin, and are what the included shell script uses.
Rust source code is provided in `rust_src` but not referenced in the shell script.

## Usage

### Stats

```
./haplotagStats -i ${/path/to/bamfile} -b ${/path/to/bedfile} > ${output.csv}
```

Options:
 - `i` : **required** path to a phased bam file (expects the PS, DP, and HP tags)
 - `l` : longform, save full window stats for plotting
 - `r` : run HPDP stats for a single region (chrX:12345-23456), only supported for short summary
 - `t` : create temporary files at this location, rather than the current working directory
 - `g` : provide alternative path to binary support files
 - `w` : window for pileup calculation (default: 1kb)
 - `b` : path to bed file with 4th column of named regions
 - `c` : include gene coverage in output (short summary only)
 - `t` : threads (passed to samtools)

Output is a tab separated file



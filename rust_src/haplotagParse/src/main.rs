use std::env;
use std::io::{self, BufRead};

fn main() {
    let args: Vec<String> = env::args().collect();

    //let stranded = &args[1];

    let g = io::stdin();
    let mut all_reads=0;
    let mut all_phase_1 = 0;
    let mut all_phase_2 = 0;
    let mut all_percent_phased = 0;
    let mut num_reads = 0;

    for aline in g.lock().lines() {
        let line = aline.expect("could not read form standard input");
		
		let frequency = calc_haplotag(&line);
        all_reads += frequency[0] as i64;
        all_phase_1 += frequency[1] as i64;
        all_phase_2 += frequency[2] as i64;
        all_percent_phased += frequency[3] as i64;
        num_reads += 1;
		// println!{"{}\t{}\t{}\t{}", frequency[0], frequency[1], frequency[2], frequency[3]}
    }
    let average_reads = all_reads/num_reads;
    let average_phase_1 = all_phase_1/num_reads;
    let average_phase_2 = all_phase_2/num_reads;
    let average_percent = all_percent_phased/num_reads;

    println!{"{}\t{}\t{}\t{}", average_reads, average_phase_1, average_phase_2, average_percent};
}

fn calc_haplotag(in_string: &str) -> [i32; 4] {
    let total_reads= in_string.matches(',').count() as i32;
    let phase_1 = in_string.matches('1').count() as i32;
    let phase_2 = in_string.matches('2').count() as i32;
    let percent_phased=((phase_1+phase_2) * 100)/((total_reads+1));

    let result_array: [i32; 4] = [(total_reads+1), phase_1, phase_2, percent_phased];
    return result_array;
}

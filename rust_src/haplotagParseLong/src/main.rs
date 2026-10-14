use std::env;
use std::io::{self, BufRead};

fn main() {
    let args: Vec<String> = env::args().collect();

    //let stranded = &args[1];

    let g = io::stdin();
    for aline in g.lock().lines() {
        let line = aline.expect("could not read form standard input");
		
		let frequency = calc_haplotag(&line);
		println!{"{},{},{},{}\n", frequency[0], frequency[1], frequency[2], frequency[3]}
    }
}

fn calc_haplotag(in_string: &str) -> [i32; 4] {
    let total_reads= in_string.matches(',').count() as i32;
    let phase_1 = in_string.matches('1').count() as i32;
    let phase_2 = in_string.matches('2').count() as i32;
    let percent_phased=((phase_1+phase_2) * 100)/((total_reads+1));

    let result_array: [i32; 4] = [(total_reads+1), phase_1, phase_2, percent_phased];
    return result_array;
}

//
// Merge paired end reads
//

params.options = [:]

def modules = params.modules.clone()

//
// MODULE: Load FLASH2
//
def flash2_options  = modules['flash2']
if (params.flash2_options) {
    flash2_options.args += " " + params.flash2_options
} 
include { FLASH2  } from '../../modules/local/flash2/main.nf' addParams( options: flash2_options )

//
// MODULE: Load SEQPREP
//
def seqprep_options  = modules['seqprep']
if (params.seqprep_options) {
    seqprep_options.args += " " + params.seqprep_options
} 
include { SEQPREP } from '../../modules/local/seqprep/read_merging/main.nf' addParams( options: seqprep_options )

//
// MODULE: Load PEAR 
//
def pear_options  = modules['pear']
if (params.pear_options) {
    pear_options.args += " " + params.pear_options
} 
include { PEAR } from '../../modules/nf-core/pear/main.nf' addParams( options: pear_options )


workflow READ_MERGING {
    take: 
        reads

    main: 
        ch_merged_reads = Channel.empty()
        if (params.read_merging == "flash2") {
            //
            // MODULE: Run FLASH
            //
            FLASH2 ( reads )
            ch_merged_reads = FLASH2.out.reads
        }
        
        if (params.read_merging == "seqprep") {
            //
            // MODULE: Run SeqPrep
            //
            SEQPREP ( reads )
            ch_merged_reads = SEQPREP.out.reads
        }

        if (params.read_merging == "pear") {
            //
            // MODULE: Run PEAR
            //
            PEAR ( reads )
            ch_merged_reads = PEAR.out.assembled
        }

    emit:
        reads = ch_merged_reads
}

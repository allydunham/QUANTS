include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process PEAR {
    tag "$meta.id"
    label 'process_high'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "bioconda::pear=0.9.6" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pear:0.9.6--h67092d7_8':
        'biocontainers/pear:0.9.6--h67092d7_8' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.assembled.fastq.gz")                                                  , emit: assembled
    tuple val(meta), path("*.unassembled.forward.fastq.gz"), path("*.unassembled.reverse.fastq.gz"), emit: unassembled
    tuple val(meta), path("*.discarded.fastq.gz")                                                  , emit: discarded
    path "versions.yml"                                                                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    def merged = "${prefix}.merged"
    """
    gunzip -f ${reads[0]}
    gunzip -f ${reads[1]}
    pear \\
        -f ${reads[0].baseName} \\
        -r ${reads[1].baseName} \\
        -o $merged \\
        -j $task.cpus \\
        -y ${task.memory.getGiga()}G \\
        $args
    gzip -f ${merged}.assembled.fastq
    gzip -f ${merged}.unassembled.forward.fastq
    gzip -f ${merged}.unassembled.reverse.fastq
    gzip -f ${merged}.discarded.fastq

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pear: \$(pear -h | grep 'PEAR v' | sed 's/PEAR v//' | sed 's/ .*//' ))
    END_VERSIONS
    """
}

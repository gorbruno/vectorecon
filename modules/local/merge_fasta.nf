process MERGE_FASTA {
    label 'process_medium'

    conda "conda-forge::sed=4.8"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'ubuntu:20.04' }"

    input:
    path consensus
    val outname
    val is_cleaned

    output:
    path '*.all.fa'     , emit: fasta
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: 'consensus'
    def outname_full = "${outname}.${prefix}.${is_cleaned ? 'cleaned.' : ''}all.fa"
    """
    cat ${consensus.join(' ')} > $outname_full

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cat: \$(echo \$(cat --version 2>&1) | sed 's/^.*coreutils) //; s/ .*\$//')
    END_VERSIONS
    """
}

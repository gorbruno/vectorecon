process TRIM_FASTA {
    tag "$meta.id"

    conda "conda-forge::sed=4.8 bioconda::seqkit=2.9.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'ubuntu:20.04' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.trimmed.fa"), emit: fasta
    path "versions.yml"                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    seqkit -is replace -p "^n+|n+\$" -r "" $args $fasta > ${prefix}.trimmed.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$(echo \$(seqkit version 2>&1) | sed 's/^.*seqkit v//')
    END_VERSIONS
    """
}

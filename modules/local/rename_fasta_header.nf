process RENAME_FASTA_HEADER {
    tag "$meta.id"

    conda "conda-forge::sed=4.8"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'ubuntu:20.04' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.fa"), emit: fasta
    path "outname.txt"           , emit: outname
    path "versions.yml"          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    outname=\$(rename_fasta_header.sh $args --dry)
    echo \${outname} > outname.txt

    if [[ -n \$outname ]]; then
      outname="\${outname}."
    fi

    rename_fasta_header.sh --fasta $fasta --name ${meta.id} --out \${outname}${prefix}.fa $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sed: \$(echo \$(sed --version 2>&1) | sed 's/^.*GNU sed) //; s/ .*\$//')
    END_VERSIONS
    """
}

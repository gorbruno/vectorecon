process UNTAR {
    tag "$archive"
    label 'process_high'

    conda "conda-forge::sed=4.8 conda-forge::grep=3.11 conda-forge::tar=1.34 conda-forge::pigz=2.8"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'ubuntu:20.04' }"

    input:
    tuple val(meta), path(archive)

    output:
    tuple val(meta), path("$prefix"), emit: untar
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args  = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    prefix    = task.ext.prefix ?: ( meta.id ? "${meta.id}" : archive.baseName.toString().replaceFirst(/\.tar$/, ""))

    """
    mkdir $prefix

    ## Ensures --strip-components only applied when top level of tar contents is a directory
    ## If just files or multiple directories, place all in prefix

    if [[ \$(tar --use-compress-program="pigz -d -p ${task.cpus} --best" -taf ${archive} | grep -o -P "^.*?\\/" | uniq | wc -l) -eq 1 ]]; then
        tar \\
            -C $prefix --strip-components 1 \\
            --use-compress-program="pigz -d -p ${task.cpus} --best" \\
            -xavf \\
            $args \\
            $archive \\
            $args2

    else
        tar \\
            -C $prefix \\
            --use-compress-program="pigz -d -p ${task.cpus} --best" \\
            -xavf \\
            $args \\
            $archive \\
            $args2
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        untar: \$(echo \$(tar --version 2>&1) | sed 's/^.*(GNU tar) //; s/ Copyright.*\$//')
        pigz: \$(pigz --version 2>&1 | sed 's/pigz //g')
    END_VERSIONS
    """

    stub:
    prefix    = task.ext.prefix ?: ( meta.id ? "${meta.id}" : archive.toString().replaceFirst(/\.[^\.]+(.gz)?$/, ""))
    """
    mkdir $prefix
    touch ${prefix}/file.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        untar: \$(echo \$(tar --version 2>&1) | sed 's/^.*(GNU tar) //; s/ Copyright.*\$//')
        pigz: \$(pigz --version 2>&1 | sed 's/pigz //g')
    END_VERSIONS
    """
}

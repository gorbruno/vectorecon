process IVAR_TRIM_STATS {
    tag "$meta.id"
    label 'process_medium'

    conda "conda-forge::csvtk=0.32.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ivar:1.4--h6b7c446_1' :
        'quay.io/biocontainers/ivar:1.4--h6b7c446_1' }"


    input:
    tuple val(meta), path(log_file)
    path bed

    output:
    tuple val(meta), path("*.primer_stats.tsv")  , emit: stats
    tuple val(meta), path("*.primer_summary.tsv"), emit: summary
    path "versions.yml"                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bed_length=\$(wc -l < $bed)
    bed_width=\$(head -1 $bed | wc -w)

    cols=("reference" "start" "end" "name" "score" "strand" "seq")
    selected_cols=\$(printf "%s," "\${cols[@]:0:bed_width}" | sed 's/,\$//')

    cat $log_file | grep "Primer Name" -A \$bed_length | tail -n +2 | csvtk add-header -t -n "name,count" > ${prefix}.ivar_table.tsv
    cat $bed | csvtk add-header -t -n \$selected_cols > ${prefix}.bed.tsv

    csvtk join -t -f name ${prefix}.ivar_table.tsv ${prefix}.bed.tsv > ${prefix}.primer_stats.tsv
    csvtk summary -t -g "strand" -f count:sum ${prefix}.primer_stats.tsv | csvtk transpose -t | cut -f2,3 > ${prefix}.primer_summary.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        csvtk: \$(csvtk version | sed 's/^csvtk v//')
    END_VERSIONS
    """
}

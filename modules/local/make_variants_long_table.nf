process MAKE_VARIANTS_LONG_TABLE {

    conda "conda-forge::python=3.12.8 conda-forge::matplotlib=3.10.0 conda-forge::pandas=2.2.3 conda-forge::r-sys=3.4.3 conda-forge::regex=2024.11.6 conda-forge::scipy=1.15.1 conda-forge::xlsxwriter=3.2.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-77320db00eefbbf8c599692102c3d387a37ef02a:08144a66f00dc7684fad061f1466033c0176e7ad-0' :
        'quay.io/biocontainers/mulled-v2-77320db00eefbbf8c599692102c3d387a37ef02a:08144a66f00dc7684fad061f1466033c0176e7ad-0' }"

    input:
    path ('bcftools_query/*')
    path ('snpsift/*')
    path ('pangolin/*')
    val  outname

    output:
    path "*.csv"       , emit: csv
    path "*.xlsx"      , optional: true, emit: excel
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:  // This script is bundled with the pipeline, in nf-core/viralrecon/bin/
    def args = task.ext.args ?: ''
    """
    make_variants_long_table.py \\
        --bcftools_query_dir ./bcftools_query \\
        --snpsift_dir ./snpsift \\
        --pangolin_dir ./pangolin \\
        $args

    if [[ $outname != "merged" ]]; then
      # find . -name "variants_long_table.*" -exec sh -c "mv \$1 ${outname}.variants.\${1##*.}" rename {} \; TODO
      mv variants_long_table.csv ${outname}.variants.csv
      mv variants_long_table.xlsx ${outname}.variants.xlsx #may fail
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}

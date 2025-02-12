process MULTIQC {
    label 'process_medium'

    conda "bioconda::multiqc=1.27 conda-forge::openpyxl=3.1.5"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.14--pyhdfd78af_0' :
        'quay.io/biocontainers/multiqc:1.14--pyhdfd78af_0' }"

    input:
    path 'multiqc_config.yaml'
    path multiqc_custom_config
    path software_versions
    path workflow_summary
    path fail_reads_summary
    path fail_mapping_summary
    path 'amplicon_heatmap_mqc.tsv'
    path ('fastqc/*')
    path ('fastp/*')
    path ('kraken2/*')
    path ('bowtie2/*')
    path ('bowtie2/*')
    path ('bowtie2/*')
    path ('ivar_trim/*')
    path ('ivar_trim/*')
    path ('ivar_trim/*')
    path ('picard_markduplicates/*')
    path ('mosdepth/*')
    path ('variants/*')
    path ('variants/*')
    path ('variants/*')
    path ('variants/*')
    path ('variants/*')
    path ('variants/*')
    path ('cutadapt/*')
    path ('assembly_spades/*')
    path ('assembly_unicycler/*')
    path ('assembly_minia/*')

    output:
    path "*multiqc_report.html"      , emit: report
    path "*_data"                    , emit: data
    path "*variants_metrics_mqc.csv" , optional:true, emit: csv_variants
    path "*assembly_metrics_mqc.csv" , optional:true, emit: csv_assembly
    path "*variants_metrics_mqc.xlsx", optional:true, emit: excel_variants
    path "*assembly_metrics_mqc.xlsx", optional:true, emit: excel_assembly
    path "*_plots"                   , optional:true, emit: plots
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def custom_config = multiqc_custom_config ? "--config $multiqc_custom_config" : ''
    """
    ## Run MultiQC once to parse tool logs
    multiqc -f $args $custom_config .

    ## Parse YAML files dumped by MultiQC to obtain metrics
    multiqc_to_custom_csv.py --platform illumina $args2

    ## Manually remove files that we don't want in the report
    if grep -q ">skip_assembly<" workflow_summary_mqc.yaml; then
        rm -f *assembly_metrics_mqc.csv
    fi

    if grep -q ">skip_variants<" workflow_summary_mqc.yaml; then
        rm -f *variants_metrics_mqc.csv
    fi

    mkdir ignore

    mv variants/report.tsv ignore
    mv variants/nextclade_clade_mqc.tsv ignore
    mv ivar_trim/ivar_trim_primer_statistics_mqc.tsv ignore

    ## Run MultiQC a second time
    multiqc -f $args -e general_stats --ignore "ignore/*" $custom_config .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$( multiqc --version | sed -e "s/multiqc, version //g" )
    END_VERSIONS
    """
}

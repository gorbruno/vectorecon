//
// iVar trim, sort, index BAM file and run samtools stats, flagstat and idxstats
//

include { IVAR_TRIM               } from '../../modules/nf-core/ivar/trim/main'
include { IVAR_TRIM_STATS         } from '../../modules/local/ivar_trim_stats'
include { BAM_SORT_STATS_SAMTOOLS } from '../nf-core/bam_sort_stats_samtools/main'

workflow BAM_TRIM_PRIMERS_IVAR {
    take:
    bam   // channel: [ val(meta), [ bam ], [bai] ]
    bed   // path   : bed
    fasta // channel: reference.fasta

    main:

    ch_versions = Channel.empty()

    //
    // iVar trim primers
    //
    IVAR_TRIM (
        bam,
        bed
    )
    ch_versions = ch_versions.mix(IVAR_TRIM.out.versions.first())

    //
    // Count primer statistic from iVar trim
    //

    IVAR_TRIM_STATS (
        IVAR_TRIM.out.log,
        bed
    )
    ch_versions = ch_versions.mix(IVAR_TRIM_STATS.out.versions)

    //
    // Sort, index BAM file and run samtools stats, flagstat and idxstats
    //
    BAM_SORT_STATS_SAMTOOLS (
        IVAR_TRIM.out.bam,
        fasta
    )
    ch_versions = ch_versions.mix(BAM_SORT_STATS_SAMTOOLS.out.versions)

    emit:
    bam_orig = IVAR_TRIM.out.bam                    // channel: [ val(meta), bam   ]
    log_out  = IVAR_TRIM.out.log                    // channel: [ val(meta), log   ]
    primer_stats = IVAR_TRIM_STATS.out.stats        // channel: [ val(meta), stats ]
    primer_summary = IVAR_TRIM_STATS.out.summary    // channel: [ val(meta), summary ]

    bam      = BAM_SORT_STATS_SAMTOOLS.out.bam      // channel: [ val(meta), [ bam ] ]
    bai      = BAM_SORT_STATS_SAMTOOLS.out.bai      // channel: [ val(meta), [ bai ] ]
    csi      = BAM_SORT_STATS_SAMTOOLS.out.csi      // channel: [ val(meta), [ csi ] ]
    stats    = BAM_SORT_STATS_SAMTOOLS.out.stats    // channel: [ val(meta), [ stats ] ]
    flagstat = BAM_SORT_STATS_SAMTOOLS.out.flagstat // channel: [ val(meta), [ flagstat ] ]
    idxstats = BAM_SORT_STATS_SAMTOOLS.out.idxstats // channel: [ val(meta), [ idxstats ] ]
    coverage = BAM_SORT_STATS_SAMTOOLS.out.coverage // channel: [ val(meta), [ coverage ] ]

    versions = ch_versions                          // channel: [ versions.yml ]
}

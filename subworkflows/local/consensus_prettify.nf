//
// Consensus renaming, trimming terminal Ns and merging
//

include { RENAME_FASTA_HEADER } from '../../modules/local/rename_fasta_header'
include { TRIM_FASTA          } from '../../modules/local/trim_fasta'
include { MERGE_FASTA         } from '../../modules/local/merge_fasta'

workflow CONSENSUS_PRETTIFY {
    take:
    fasta // channel: [ val(meta), [ fasta ] ]

    main:

    ch_versions = Channel.empty()

    //
    // Rename consensus header adding sample name (and optional date, run number and agent)
    //
    RENAME_FASTA_HEADER (
        fasta
    )
    ch_consensus = RENAME_FASTA_HEADER.out.fasta
    ch_versions = ch_versions.mix(RENAME_FASTA_HEADER.out.versions.first())
    ch_outname = RENAME_FASTA_HEADER.out.outname
            .map { it.text }
            .first()
            .map { WorkflowCommons.checkOutname(it) }

    //
    // Merge fasta to one big consensus file
    //
    MERGE_FASTA (
      RENAME_FASTA_HEADER.out.fasta.collect{ it[1] },
      ch_outname,
      false // is_trimmed = false
    )
    ch_consensus_merged = MERGE_FASTA.out.fasta
    ch_versions = ch_versions.mix(MERGE_FASTA.out.versions)

    //
    // Trim and merge terminal Ns if specified
    //
    ch_trimmed_consensus = Channel.empty()
    ch_trimmed_consensus_merged = Channel.empty()
    if (params.trim_consensus_n) {
      TRIM_FASTA (
        RENAME_FASTA_HEADER.out.fasta
      )
      ch_trimmed_consensus = TRIM_FASTA.out.fasta
      ch_versions = ch_versions.mix(TRIM_FASTA.out.versions.first())

      MERGE_FASTA (
        TRIM_FASTA.out.fasta.collect{ it[1] },
        ch_outname,
        true // is_trimmed = true
      )
      ch_trimmed_consensus_merged = MERGE_FASTA.out.fasta
    }

    emit:
    fasta         = ch_consensus                    // channel: [ val(meta), [ fasta ] ]
    merged            = ch_consensus_merged         // channel: [ path "*.all.fa" ]
    fasta_trimmed = ch_trimmed_consensus            // channel: [ val(meta), [ fasta ] ]
    merged_trimmed    = ch_trimmed_consensus_merged // channel: [ path "*.trimmed.all.fa" ]

    versions         = ch_versions                  // channel: [ versions.yml ]
}

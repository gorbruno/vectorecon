//
// Consensus renaming, cleaning terminal Ns and merging
//

include { RENAME_FASTA_HEADER                } from '../../modules/local/rename_fasta_header'
include { CLEAN_FASTA                        } from '../../modules/local/clean_fasta'
include { MERGE_FASTA as MERGE_FASTA_RAW     } from '../../modules/local/merge_fasta'
include { MERGE_FASTA as MERGE_FASTA_CLEANED } from '../../modules/local/merge_fasta'

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
            .map { WorkflowCommons.checkOutname(it) } // val

    //
    // Merge fasta to one big consensus file
    //
    MERGE_FASTA_RAW (
      RENAME_FASTA_HEADER.out.fasta.collect{ it[1] },
      ch_outname,
      false // is_cleaned = false
    )
    ch_consensus_merged = MERGE_FASTA_RAW.out.fasta
    ch_versions = ch_versions.mix(MERGE_FASTA_RAW.out.versions)

    //
    // Clean and merge terminal Ns if specified
    //
    ch_cleaned_consensus = Channel.empty()
    ch_cleaned_consensus_merged = Channel.empty()
    if (params.clean_consensus_n) {
      CLEAN_FASTA (
        RENAME_FASTA_HEADER.out.fasta
      )
      ch_cleaned_consensus = CLEAN_FASTA.out.fasta
      ch_versions = ch_versions.mix(CLEAN_FASTA.out.versions.first())

      MERGE_FASTA_CLEANED (
        CLEAN_FASTA.out.fasta.collect{ it[1] },
        ch_outname,
        true // is_cleaned = true
      )
      ch_cleaned_consensus_merged = MERGE_FASTA_CLEANED.out.fasta
    }

    emit:
    fasta          = ch_consensus                // channel: [ val(meta), [ fasta ] ]
    merged         = ch_consensus_merged         // channel: [ path "*.all.fa" ]
    fasta_cleaned  = ch_cleaned_consensus        // channel: [ val(meta), [ fasta ] ]
    merged_cleaned = ch_cleaned_consensus_merged // channel: [ path "*.cleaned.all.fa" ]
    outname        = ch_outname                  // channel: [ val outname ]

    versions         = ch_versions                  // channel: [ versions.yml ]
}

# process T2TXY_v2.7.dip.vcf to match hifiDV GT using JZ sed command `


rule fix_XY_genotype:
    input:
        "results/draft_benchmarksets/{bench_id}/intermediates/{prefix}.vcf.gz",
    output:
        "results/draft_benchmarksets/{bench_id}/intermediates/{prefix}.fix_XY_genotype.vcf.gz",
    conda:
        "../envs/dipcall.yml"
    log:
        "logs/fix_XY_genotype/{bench_id}_{prefix}.log",
    shell:
        """
        gunzip -c {input} \
            | sed 's/\.|1/1\/1/;s/1|\./1\/1/' \
            | bgzip -c \
            > {output}
        """


## Use when evaluating assembly accuracy with established benchmark
##  This rule is an artifact from previous assembly benchmarking pipeline
##  Not current used - keeping here for potential future use
rule dip_gap2homvarbutfiltered:
    input:
        "results/draft_benchmarksets/{bench_id}/intermediates/{prefix}.vcf.gz",
    output:
        "results/draft_benchmarksets/{bench_id}/intermediates/{prefix}.gap2homvarbutfiltered.vcf.gz",
    # bgzip is part of samtools, which is part of the dipcall env
    conda:
        "../envs/dipcall.yml"
    log:
        "logs/dip_gap2homvarbutfiltered/{bench_id}_{prefix}.log",
    shell:
        """
        gunzip -c {input} |\
        sed 's/1|\./1|1/' |\
        grep -v 'HET\|GAP1\|DIP' |\
        bgzip -c > {output}
        """


## Primarily for SVs
rule split_multiallelic_sites:
    input:
        "results/draft_benchmarksets/{bench_id}/intermediates/{prefix}.vcf.gz",
    output:
        vcf="results/draft_benchmarksets/{bench_id}/intermediates/{prefix}.split_multi.vcf.gz",
        vcf_tbi="results/draft_benchmarksets/{bench_id}/intermediates/{prefix}.split_multi.vcf.gz.tbi",
    conda:
        "../envs/bcftools.yml"
    log:
        "logs/split_multiallelic_sites/{bench_id}_{prefix}.log",
    shell:
        """
        bcftools norm -m - {input} -Oz -o {output.vcf} 2> {log}
        tabix -p vcf {output.vcf} 2>> {log}
        """


rule move_asm_vcf_to_draft_bench:
    input:
        lambda wildcards: f"results/asm_varcalls/{bench_tbl.loc[wildcards.bench_id, 'vc_id']}/{{prefix}}.dip.vcf.gz",
    output:
        "results/draft_benchmarksets/{bench_id}/intermediates/{prefix}.vcf.gz",
    log:
        "logs/process_benchmark_vcf/{bench_id}_{prefix}.log",
    shell:
        "cp {input} {output} &> {log}"


rule move_processed_draft_bench_vcf:
    input:
        get_processed_vcf,
    output:
        "results/draft_benchmarksets/{bench_id}/{ref_id}_{asm_id}_{vc_cmd}-{vc_param_id}.vcf.gz",
    log:
        "logs/move_processed_draft_bench_vcf/{bench_id}_{ref_id}_{asm_id}_{vc_cmd}-{vc_param_id}.log",
    shell:
        "cp {input} {output}"
################################################################################
## Utility Functions

## Loading and validating analysis tables
def get_analyses(path):
    # target_regions must be a string even though it might only contain
    # 'boolean' values
    analyses = pd.read_table(path, dtype={"eval_target_regions": str})
    validate(analyses, "schema/analyses-schema.yml")

    try:
        return analyses.set_index("eval_id", verify_integrity=True)
    except ValueError:
        print("All keys in column 'eval_id' must by unique")


## Generating concatenated string for wildcard constraints
def format_constraint(xs):
    return "|".join(set(xs))


################################################################################
## Rule parameters


def get_male_bed(wildcards):
    is_male = asm_config[wildcards.asm_id]["is_male"]
    root = config["_par_bed_root"]
    par_path = Path(root) / ref_config[wildcards.ref_id]["par_bed"]
    return f"-x {str(par_path)}" if is_male else ""


## Happy Inputs and Parameters
def get_happy_inputs(wildcards):
    ## Creating empty dictionary for storing inputs
    inputs = {}

    ## Reference genome and stratifications
    ref_id = analyses.loc[wildcards.eval_id, "ref"]
    inputs["genome"] = f"resources/references/{ref_id}.fa"
    inputs["genome_index"] = f"resources/references/{ref_id}.fa.fai"
    strat_tb = config['stratifications'][wildcards.ref_id]['tarball']
    inputs["strat_tb"] = f"resources/strats/{ref_id}/{strat_tb}"


    ## draft benchmark variant calls
    draft_bench_vcf = "results/draft_benchmarksets/{bench_id}/{ref_id}_{asm_id}_{vc_cmd}-{vc_param_id}.vcf.gz"

    ## draft benchmark regions
    if analyses.loc[(wildcards.eval_id, "exclusion_set")] == "none":
        draft_bench_bed = "results/draft_benchmarksets/{bench_id}/{ref_id}_{asm_id}_{vc_cmd}-{vc_param_id}.bed"
    else:
        draft_bench_bed = "results/draft_benchmarksets/{bench_id}/{ref_id}_{asm_id}_{vc_cmd}-{vc_param_id}.excluded.bed"

    ## comparison variant call paths
    comp_vcf = "resources/comparison_variant_callsets/{comp_id}.vcf.gz"
    comp_vcfidx = "resources/comparison_variant_callsets/{comp_id}.vcf.gz.tbi"
    comp_bed = "resources/comparison_variant_callsets/{comp_id}.bed"

    ## Determining which callsets and regions are used as truth
    if analyses.loc[wildcards.eval_id, "eval_comp_id_is_truth"] == True:
        query = "draft_bench"
    else:
        query = "comp"

    ## Defining truth calls and regions along with query calls
    if query == "draft_bench":
        inputs["query"] = draft_bench_vcf
        inputs["truth"] = comp_vcf
        inputs["truth_vcfidx"] = comp_vcfidx
        inputs["truth_regions"] = comp_bed
    else:
        inputs["query"] = comp_vcf
        inputs["query_vcfidx"] = comp_vcfidx
        inputs["truth"] = draft_bench_vcf
        inputs["truth_regions"] = draft_bench_bed

    ## Determining Target regions
    trs = eval_tbl.loc[wildcards.eval_id, "eval_target_regions"]
    if trs.lower() != "false":
        if trs.lower() == "true":
            if query == "draft_bench":
                inputs["target_regions"] = draft_bench_bed
            else:
                inputs["target_regions"] = comp_bed
        else:
            inputs["target_regions"] = f"resources/manual/target_regions/{trs}"

    ## Returning happy inputs
    return inputs


## Exclusions
def lookup_excluded_region_set(wildcards):
    xset = bench_tbl.loc[wildcards.bench_id]["exclusion_set"]
    return [
        f"results/draft_benchmarksets/{{bench_id}}/{{ref_id}}_{{asm_id}}_{{vc_cmd}}-{{vc_param_id}}_exclusions/{p}"
        for p in config["exclusion_set"][xset]
    ]

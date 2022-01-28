#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Author: Nathan Olson
from os import path
from snakemake.shell import shell

log = snakemake.log_fmt_shell(stdout=False, stderr=True)

## Optional parameters
engine = snakemake.params.get("engine", "")
if engine:
    engine = f"--engine {engine}"

truth_regions = snakemake.input.get("truth_regions", "")
if truth_regions:
    truth_regions = f"-f {truth_regions}"

target_regions = snakemake.input.get("target_regions", "")
if target_regions:
    target_regions = f"-T {target_regions}"

## Extracting stratification tarball
ref_id = snakemake.wildcards.ref_id
strat_id = snakemake.config["stratifications"][ref_id]["id"]
strat_dir = f"resources/stratifications/{strat_id}"
strat_tsv = f"{strat_dir}/{snakemake.params.strat_tsv}"
if path.isdir(strat_dir):
    print("Strafications Directory Exists")
else:
    print("Making directory to extract stratifications into")
    shell("mkdir -p {strat_dir}", "{log}")

if path.isfile(strat_tsv):
    print("Stratification tsv file present")
else:
    print("Extracting Stratifications")
    shell("tar -xvf {snakemake.input.strat_tb} -C {strat_dir}", "{log}")


## Running Happy
shell(
    "(hap.py "
    "    --threads {snakemake.params.threads} "
    "    {engine} "
    "    -r {snakemake.input.genome}  "
    "    {truth_regions} "
    "    --stratification {strat_tsv} "
    "    -o {snakemake.params.prefix} "
    "    --verbose "
    "    {target_regions} "
    "    {snakemake.input.truth} "
    "    {snakemake.input.query} )"
    "{log}"
)
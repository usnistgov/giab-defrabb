import os
import sys

import subprocess as sp
from tempfile import TemporaryDirectory
import shutil
from pathlib import Path, PurePosixPath

sys.path.insert(0, os.path.dirname(__file__))

import common


def test_run_happy():
    with TemporaryDirectory() as tmpdir:
        workdir = Path(tmpdir) / "workdir"
        data_path = PurePosixPath(".tests/unit/run_happy/data")
        expected_path = PurePosixPath(".tests/unit/run_happy/expected")
        config_path = PurePosixPath("config")
        references_path = PurePosixPath(".tests/integration/resources/references")

        # Copy data to the temporary workdir.
        shutil.copytree(data_path, workdir)
        shutil.copytree(config_path, workdir / "config")
        shutil.copytree(references_path, workdir / "resources" / "references")

        # dbg
        print(
            "results/evaluations/happy/eval1_testA/GRCh38_chr21_v4.2.1chr21_asm17aChr21_smvar_dipcall-default.extended.csv",
            file=sys.stderr,
        )

        # Run the test job.
        sp.check_output(
            [
                "python",
                "-m",
                "snakemake",
                "results/evaluations/happy/eval1_testA/GRCh38_chr21_v4.2.1chr21_asm17aChr21_smvar_dipcall-default.extended.csv",
                "-f",
                "-j1",
                "--keep-target-files",
                "--touch",
                "--use-conda",
                "--directory",
                workdir,
            ]
        )

        # Check the output byte by byte using cmp.
        # To modify this behavior, you can inherit from common.OutputChecker in here
        # and overwrite the method `compare_files(generated_file, expected_file),
        # also see common.py.
        common.OutputChecker(
            data_path, expected_path, workdir, ignore_unexpected=True
        ).check()

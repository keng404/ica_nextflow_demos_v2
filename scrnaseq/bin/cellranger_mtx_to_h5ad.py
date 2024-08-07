#!/usr/bin/env python
import scanpy as sc
import argparse

import os
os.environ[ 'NUMBA_CACHE_DIR' ] = '/tmp/'

def mtx_to_adata(mtx_h5: str, sample: str, verbose: bool = False):

    if verbose:
        print("Reading in {}".format(mtx_h5))

    adata = sc.read_10x_h5(mtx_h5)
    adata.var["gene_symbols"] = adata.var_names
    adata.var.set_index("gene_ids", inplace=True)
    adata.obs["sample"] = sample

    return adata


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="Converts mtx output to h5ad.")

    parser.add_argument("-m", "--mtx", dest="mtx", help="Path to mtx h5 file.")
    parser.add_argument("-v", "--verbose", dest="verbose", help="Toggle verbose messages", default=False)
    parser.add_argument("-s", "--sample", dest="sample", help="Sample name")
    parser.add_argument("-o", "--out", dest="out", help="Output path.")

    args = vars(parser.parse_args())

    adata = mtx_to_adata(args["mtx"], args["sample"], verbose=args["verbose"])

    adata.write_h5ad(args["out"], compression="gzip")

    print("Wrote h5ad file to {}".format(args["out"]))

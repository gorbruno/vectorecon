#!/usr/bin/env python

from matplotlib import table
import pandas as pd
import sys
import numpy as np
import re
import argparse
import glob, os
import io

pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)


def parser_args(args=None):
    Description = 'Create long/wide tables fo ivar/bcftools'
    Epilog = """Example usage: python parser_ivar_bcftools.py <sample> <snpsift> <pangolin> <software> """
    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument('-sample', help="Input sample table files path." )
    parser.add_argument('-snpsift', help="Input snpsift txt files path.",required=True)
    parser.add_argument('-pangolin', help="Input pangolin csv files path.",required=True)
    parser.add_argument('-software', help="Input bcftools of ivar.",required=True)

    return parser.parse_args(args)


def create_long(snp_file,snpsift_file,pangolin_file,software):

    ### format of sample table
    snp_table=pd.read_table(snp_file, header='infer')
    snp_table = snp_table.dropna(how = 'all', axis =1)

    if software=='bcftools':
        snp_table.rename(columns={snp_table.columns[5]: "DP",snp_table.columns[6]: "AD"}, inplace=True)
        new_column = snp_table
        new_column[['REF_DP','ALT_DP']] = snp_table['AD'].str.split(',', expand=True)
        snp_table = pd.merge(snp_table,new_column,how = 'left')
        snp_table[["ALT_DP", "DP"]] = snp_table[["ALT_DP", "DP"]].apply(pd.to_numeric)
        snp_table['AF']=snp_table['ALT_DP']/snp_table['DP']
        snp_table['AF'] = snp_table['AF'].round(2)
        snp_table = snp_table.loc[:, ~snp_table.columns.str.contains('AD')]

    elif software=='ivar':
        snp_table.rename(columns={snp_table.columns[0]: "CHROM",snp_table.columns[1]: "POS",snp_table.columns[2]: "REF",snp_table.columns[3]: "ALT",snp_table.columns[4]: "FILTER",snp_table.columns[5]: "DP",snp_table.columns[6]: "REF_DP", snp_table.columns[7]: "ALT_DP"}, inplace=True)
        snp_table[["ALT_DP", "DP"]] = snp_table[["ALT_DP", "DP"]].apply(pd.to_numeric)
        snp_table['AF']=snp_table['ALT_DP']/snp_table['DP']
        snp_table['AF'] = snp_table['AF'].round(2)

    ### format of snpsift table
    snpsift_table = pd.read_csv(snpsift_file, sep="\t", header = "infer")
    snpsift_table = snpsift_table.loc[:, ~snpsift_table.columns.str.contains('^Unnamed')]
    colnames_snpsift = list(snpsift_table.columns)
    colnames_snpsift = [i.replace('ANN[*].', '') for i in colnames_snpsift]
    for i in range(len(colnames_snpsift)):
       snpsift_table.rename(columns = {snpsift_table.columns[i]:colnames_snpsift[i]}, inplace = True)
    snpsift_table =  snpsift_table.loc[:, ['CHROM','POS','REF','ALT','GENE','EFFECT','HGVS_C','HGVS_P']]

    snpsift_table_copy = snpsift_table.copy()

    for i in  range(len(snpsift_table_copy)):
        for j in range(3,8):
         snpsift_table_copy.iloc[i,j]= str(snpsift_table.iloc[i,j]).split(",")[0]

    #format of lineages
    pangolin_table = pd.read_csv(pangolin_file, sep=",", header = "infer")
    lineages = pangolin_table.loc[:,['taxon','lineage']]

    #table long one sample
    tl_onesample = pd.DataFrame(data =snp_table)
    if software=='bcftools':
        tl_onesample["Sample"] = lineages.iloc[0,0]
    elif software=='ivar':
        tl_onesample["Sample"] = lineages.iloc[0,0].split('_')[1].split('.')[0]
    tl_onesample["software"] = software
    tl_onesample["Lineage"] = lineages.iloc[0,1]

    merged_table_long = pd.merge(tl_onesample,snpsift_table_copy,how = 'outer')

    return(merged_table_long)

def same_len(list):
    return len(set(list)) == 1

def concatenatetable(path):
    all_filenames = [file for file in glob.glob(path + '/*.csv')]

    dataframe_list = []
    for file in all_filenames:
        dataframe_list.append(pd.read_csv(file,sep=","))
    merged_df = pd.concat(dataframe_list)
    return merged_df

def main(args=None):
    args = parser_args(args)

    # List vcf table files
    table_list = []
    for file in glob.glob(args.sample + "/*_norm.table"):
        table_list.append(file)
    table_list.sort()

    #List snpsift files
    snpsift_list = []
    for file in glob.glob(args.snpsift + "/*_norm.snpsift.txt"):
        snpsift_list.append(file)
    snpsift_list.sort()

    # List pangolin files
    pangolin_list = []
    for file in glob.glob(args.pangolin + "/*.csv"):
        pangolin_list.append(file)
    pangolin_list.sort()

    if not same_len([len(table_list),len(snpsift_list),len(pangolin_list)]):
        print("not same number of files for variants, snpsift and pangolin results ")
        exit()

    sample_names = [os.path.basename(filename).split("_norm.table")[0] for filename in table_list]

    #create SampleTables folder in the folder where the script is running
    if os.path.exists("SampleTables"):
        "SampleTables already exists from previous run, please delete or rename the folder."
    else:
        os.mkdir("SampleTables")

    for sample_name,table,snpsift,pangolin in zip(sample_names,table_list,snpsift_list,pangolin_list):
        long_table_sample = create_long(table,snpsift,pangolin,args.software)
        long_table_sample.to_csv('./SampleTables/'+ sample_name + '.csv', header='infer', index=None, sep=',', mode='a')

    merged_df= concatenatetable("./SampleTables")
    merged_df.to_csv("final_long_table.csv", index=False, encoding='utf-8-sig')

if __name__ == '__main__':
    sys.exit(main())

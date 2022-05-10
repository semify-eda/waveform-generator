#!/usr/bin/env python3
# SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
# SPDX-License-Identifier: Apache-2.0

import os
import sys
import csv
import json
import argparse
import pathlib

def dir_path(string):
    path = pathlib.Path(string)
    
    if not path.exists():
        raise argparse.ArgumentTypeError(f"{path} does not exist")
    
    if not path.is_dir():
        raise argparse.ArgumentTypeError(f"{path} is not a directory")

    return string

def file_path(string):
    path = pathlib.Path(string)
    
    if not path.exists():
        raise argparse.ArgumentTypeError(f"{path} does not exist")
    
    if not path.is_file():
        raise argparse.ArgumentTypeError(f"{path} is not a file")

    return string

def main():
    parser = argparse.ArgumentParser(description='Generate code blocks from templates inside files.')
    parser.add_argument('-i', '--input', type=file_path, nargs='+', required=True, help='input file')
    parser.add_argument('-o', '--output', type=str, nargs='+', help='output file, if not set equals input file')
    parser.add_argument('-v', '--verbose', action='store_true', help='verbose output')

    args = parser.parse_args()
    
    # Set file names
    in_filenames = [pathlib.Path(input) for input in args.input]
    out_filenames = [pathlib.Path(output) for output in args.output]
    
    if len(in_filenames) != len(out_filenames):
        print('Error: The number of input and output files must be equal')
        sys.exit(0)
    
    for (file_cnt, in_filename) in enumerate(in_filenames):
        out_filename = out_filenames[file_cnt]
        
        if in_filename.suffix != ".csv":
            print("Currently only .csv files can be converted")
            sys.exit(0)
        
        if args.verbose:
            print("in_filename: {}".format(in_filename))
            print("out_filename: {}".format(out_filename))
        
        json_dict = {"registers" : {}}

        with open(in_filename, 'r') as f_csv:
            csv_reader = csv.DictReader(f_csv)

            last_register = None

            for entry in csv_reader:
                if args.verbose:
                    print("Current entry: {}".format(entry))
                
                # Register
                if entry['RegName'] != '':
                    last_register = entry['RegName']
                    json_dict["registers"][entry['RegName']] = {"address" : entry['Address'],
                                                                "description" : entry['Description'],
                                                                "entries" : {}
                                                                }
                else:
                    json_dict["registers"][last_register]["entries"][entry['BitName']] = {"access" : entry['Access'],
                                                                        "hardware" : entry['HW'],
                                                                        "LSB" : entry['LSB'],
                                                                        "MSB" : entry['MSB'],
                                                                        "reset" : entry['Reset'],
                                                                        "description": entry['Description']
                                                                        }

        if args.verbose:
            print("Complete dictionary:")
            print(json_dict)
        
        with open(out_filename, "w") as f_json:
            json.dump(json_dict, f_json, indent=4, sort_keys=True)

    print("Library conversion done.")

if __name__ == "__main__":
    main()

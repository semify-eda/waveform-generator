#!/usr/bin/env python3
# SPDX-FileCopyrightText: © 2022 semify <office@semify-eda.com>
# SPDX-License-Identifier: Apache-2.0

import sys
import csv
import json
import argparse
import pathlib
from jinja2 import Environment, FileSystemLoader

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
    parser.add_argument('-d', '--data_dir', type=dir_path,  help='base data directory')
    parser.add_argument('-t', '--template_dir', type=dir_path,  help='base template directory')
    parser.add_argument('-v', '--verbose', action='store_true', help='print generated code')

    args = parser.parse_args()
    
    # Set file names
    in_filenames = [pathlib.Path(input) for input in args.input]
    
    if args.output == None:
        out_filenames = in_filenames
    else:
        out_filenames = [pathlib.Path(output) for output in args.output]
    
    if args.data_dir == None:
        data_dir = None
    else:
        data_dir = pathlib.Path(args.data_dir)

    if args.template_dir == None:
        template_dir = None
    else:
        template_dir = pathlib.Path(args.template_dir)
        
    # Jinja file loader
    file_loader = FileSystemLoader(searchpath='/')
    env = Environment(loader=file_loader)
    
    for (file_cnt, in_filename) in enumerate(in_filenames):
    
        out_filename = out_filenames[file_cnt]
    
        input_file_content = ""
        output_file_content = ""
        
        with open(in_filename, "r") as input_file:
            input_file_content = input_file.read()

        read_data = False
        read_template = False
        read_code = False
        
        data = None
        template = None
        
        for line in input_file_content.split('\n'):
        
            if read_code:
                if "marker_template_end" in line:
                    read_code = False
                    
                    whitespace = line[:len(line) - len(line.lstrip())]
                    
                    # Insert generated content
                    generated_content = template.render(data)
                    
                    if args.verbose:
                        print(generated_content)
                    
                    for generated_line in generated_content.split('\n'):
                        output_file_content += whitespace + generated_line + "\n"
     
                    output_file_content += line + "\n"
                continue
        
            if read_data:
                if data_dir:
                    datapath = data_dir / line.strip().split("data:")[1].strip()
                else:
                    datapath = in_filename.parent / line.strip().split("data:")[1].strip()
                
                if not datapath.exists():
                    print('Error: Data file {} does not exist'.format(datapath))
                
                if datapath.suffix == ".json":
                    with open(datapath, "r") as f_json:
                        data = json.load(f_json)
                else:
                    sys.exit("Datatype not supported: " + datapath)
                
                output_file_content += line + "\n"
                read_data = False
                read_template = True
                continue
                
            if read_template:
                if template_dir:
                    templatepath = template_dir / line.strip().split("template:")[1].strip()
                else:
                    templatepath = in_filename.parent / line.strip().split("template:")[1].strip()
                
                if not templatepath.exists():
                    print('Error: Template file {} does not exist'.format(templatepath))
                
                template = env.get_template(str(templatepath.resolve()))
                output_file_content += line + "\n"
                read_template = False
                continue
            
            if "marker_template_start" in line:
                output_file_content += line + "\n"
                read_data = True
                continue
                
            if "marker_template_code" in line:
                output_file_content += line + "\n"
                read_code = True
                continue

            output_file_content += line + "\n"

        # Remove last \n
        output_file_content = output_file_content[:-1]

        if args.verbose:
            print(output_file_content, end='')
        
        original_output_file_content = None
        if out_filename.is_file():
            with open(out_filename, "r") as output_file:
                original_output_file_content = output_file.read()
        
        if output_file_content == original_output_file_content:
            print("Generated file is the same as the output file at {}.".format(out_filename))
        else:
            print("Writing to file {}".format(out_filename))
            with open(out_filename, "w") as output_file:
                output_file.write(output_file_content)
                
    print("Template generation done.")

if __name__ == "__main__":
    main()

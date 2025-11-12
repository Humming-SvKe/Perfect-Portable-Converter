#!/usr/bin/env python3
"""
Minimal CLI for Perfect Portable Converter.
Supports basic text operations: uppercase, lowercase, replace.
"""
import argparse
import re
import sys


def op_uppercase(text: str) -> str:
    """Convert text to uppercase."""
    return text.upper()


def op_lowercase(text: str) -> str:
    """Convert text to lowercase."""
    return text.lower()


def op_replace(text: str, pattern: str = "", replacement: str = "") -> str:
    """Replace text using regex pattern."""
    if not pattern:
        return text
    return re.sub(pattern, replacement, text)


def convert_file(input_path: str, output_path: str, operation: str, **kwargs):
    """
    Read input file, apply operation, write to output file.
    
    Args:
        input_path: Path to input file
        output_path: Path to output file
        operation: Operation to apply (uppercase, lowercase, replace)
        **kwargs: Additional arguments for operations (e.g., pattern, replacement for replace)
    """
    try:
        with open(input_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except FileNotFoundError:
        raise FileNotFoundError(f"Input file not found: {input_path}")
    except IOError as e:
        raise IOError(f"Error reading input file {input_path}: {e}")
    
    if operation == 'uppercase':
        result = op_uppercase(content)
    elif operation == 'lowercase':
        result = op_lowercase(content)
    elif operation == 'replace':
        pattern = kwargs.get('pattern', '')
        if not pattern:
            raise ValueError("Pattern is required for replace operation")
        result = op_replace(content, pattern, kwargs.get('replacement', ''))
    else:
        raise ValueError(f"Unknown operation: {operation}")
    
    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(result)
    except IOError as e:
        raise IOError(f"Error writing output file {output_path}: {e}")



def make_parser() -> argparse.ArgumentParser:
    """Create and configure argument parser."""
    parser = argparse.ArgumentParser(
        prog='ppc',
        description='Perfect Portable Converter - minimal text conversion CLI'
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # convert subcommand
    convert_parser = subparsers.add_parser('convert', help='Convert a file')
    convert_parser.add_argument('--input', '-i', required=True, help='Input file path')
    convert_parser.add_argument('--output', '-o', required=True, help='Output file path')
    convert_parser.add_argument('--op', required=True, choices=['uppercase', 'lowercase', 'replace'],
                               help='Operation to apply')
    convert_parser.add_argument('--pattern', help='Regex pattern for replace operation')
    convert_parser.add_argument('--replacement', default='', help='Replacement string for replace operation')
    
    return parser


def main():
    """Main entry point for the CLI."""
    parser = make_parser()
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    if args.command == 'convert':
        try:
            convert_file(
                input_path=args.input,
                output_path=args.output,
                operation=args.op,
                pattern=getattr(args, 'pattern', None),
                replacement=getattr(args, 'replacement', '')
            )
            print(f"Successfully converted {args.input} -> {args.output} using {args.op}")
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)


if __name__ == '__main__':
    main()

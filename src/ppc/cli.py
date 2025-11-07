"""Minimal CLI for text file conversion operations."""
import argparse
import re
import sys
from pathlib import Path


def op_uppercase(text: str) -> str:
    """Convert text to uppercase."""
    return text.upper()


def op_lowercase(text: str) -> str:
    """Convert text to lowercase."""
    return text.lower()


def op_replace(text: str, pattern: str = "", replacement: str = "") -> str:
    """Replace pattern with replacement using regex."""
    if not pattern:
        return text
    return re.sub(pattern, replacement, text)


def convert_file(input_path: Path, output_path: Path, operation: str, 
                 pattern: str = "", replacement: str = "") -> None:
    """Convert input file using specified operation and write to output file."""
    with open(input_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if operation == 'uppercase':
        result = op_uppercase(content)
    elif operation == 'lowercase':
        result = op_lowercase(content)
    elif operation == 'replace':
        result = op_replace(content, pattern, replacement)
    else:
        raise ValueError(f"Unknown operation: {operation}")
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(result)


def make_parser() -> argparse.ArgumentParser:
    """Create and return the argument parser."""
    parser = argparse.ArgumentParser(
        description='Perfect Portable Converter - minimal text conversion CLI'
    )
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Convert subcommand
    convert_parser = subparsers.add_parser('convert', help='Convert a text file')
    convert_parser.add_argument('--input', '-i', required=True, 
                                help='Input file path')
    convert_parser.add_argument('--output', '-o', required=True,
                                help='Output file path')
    convert_parser.add_argument('--op', required=True,
                                choices=['uppercase', 'lowercase', 'replace'],
                                help='Operation to perform')
    convert_parser.add_argument('--pattern', default='',
                                help='Pattern for replace operation (regex)')
    convert_parser.add_argument('--replacement', default='',
                                help='Replacement for replace operation')
    
    return parser


def main() -> int:
    """Main entry point for the CLI."""
    parser = make_parser()
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return 1
    
    if args.command == 'convert':
        try:
            input_path = Path(args.input)
            output_path = Path(args.output)
            
            if not input_path.exists():
                print(f"Error: Input file '{args.input}' not found", file=sys.stderr)
                return 1
            
            convert_file(
                input_path, 
                output_path, 
                args.op,
                getattr(args, 'pattern', ''),
                getattr(args, 'replacement', '')
            )
            print(f"Conversion complete: {args.input} -> {args.output}")
            return 0
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            return 1
    
    return 0


if __name__ == '__main__':
    sys.exit(main())

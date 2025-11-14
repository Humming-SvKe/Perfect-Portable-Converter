"""Tests for ppc CLI."""
import pytest
from pathlib import Path
from ppc.cli import op_uppercase, op_replace, convert_file


def test_uppercase(tmp_path):
    """Test uppercase operation."""
    input_file = tmp_path / "input.txt"
    output_file = tmp_path / "output.txt"
    
    input_file.write_text("hello world")
    convert_file(input_file, output_file, "uppercase")
    
    result = output_file.read_text()
    assert result == "HELLO WORLD"


def test_replace(tmp_path):
    """Test replace operation with regex."""
    input_file = tmp_path / "input.txt"
    output_file = tmp_path / "output.txt"
    
    input_file.write_text("hello world")
    convert_file(input_file, output_file, "replace", pattern="world", replacement="universe")
    
    result = output_file.read_text()
    assert result == "hello universe"

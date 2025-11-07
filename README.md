# Perfect-Portable-Converter

Jednoduché, rozšíriteľné CLI na konverziu textových súborov.

Rýchly štart:
1) Lokálne (Linux/macOS):
   python -m venv .venv
   source .venv/bin/activate
   pip install -e .
   ppc --help

2) Príklad:
   ppc convert --input sample.txt --output out.txt --op uppercase

Testy:
   pip install pytest
   pytest -q

Popis:
- CLI `ppc` s príkazom `convert` podporuje operácie: uppercase, lowercase, replace (regex).
- Projekt používa pyproject.toml a entry-point `ppc = "ppc.cli:main".
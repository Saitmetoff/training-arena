"""Run an exact command once and append its real output to the WP evidence log."""
import argparse
import subprocess
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

parser = argparse.ArgumentParser()
parser.add_argument('--section', required=True)
parser.add_argument('--cwd', default='.')
parser.add_argument('command', nargs=argparse.REMAINDER)
args = parser.parse_args()
command = args.command
if command and command[0] == '--':
    command = command[1:]
root = Path(__file__).resolve().parents[1]
result = subprocess.run(command, cwd=root / args.cwd, stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT, text=True, encoding='utf-8', errors='replace')
output = result.stdout
with (root / 'docs/audit/FIX_LOG.md').open('a', encoding='utf-8') as log:
    log.write('\n## ' + args.section + '\n\nCommand: `' + subprocess.list2cmdline(command)
              + '`\nWorking directory: `' + str(root / args.cwd) + '`\nExit code: '
              + str(result.returncode) + '\n```text\n' + output + '\n```\n')
print(output)
print('Recorded exit code:', result.returncode)
raise SystemExit(result.returncode)

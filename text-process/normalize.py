import unicodedata
import sys

#Unicode正規化
def nfkcd(lines):
    for line in lines:
        print(unicodedata.normalize("NFKC", line))

def main():
    args = sys.argv
    if len(args) < 2:
        print("コーパスを指定してください")
        sys.exit(1)
    f = open(args[1], encoding='utf-8')
    lines = f.read().split('\n')
    f.close()
    nfkcd(lines)

if __name__ == "__main__":
    main()

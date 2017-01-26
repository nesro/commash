# commash
Comma-shell, an interactive shell debugger

The best way to install is to clone this pository into your home directory and run the main file
	git clone https://github.com/nesro/commash ~/.commash
	bash ~/.commash/comma.sh

To uninstall and clean up, run the uninstall script:
	bash ~/.commash/uninstall.sh



# bashlex
bashlex is used for parsing the command. so we run only parts

![debugger_v0](./miscs/debugger_v0.png)

# safe commands
Commash can alias basics commands (such as rm) and builtins (such as cd) to internal functions written in bash. It can provide more verbose information, tips and it allows easily to revert the command you run (such as restore deleted file).

- https://www.gnu.org/software/coreutils/coreutils.html
- http://lingrok.org/xref/coreutils/tests/

# diploma thesis
This work is being done as my diploma thesis, here are instructions in the czech language:
 - Proveďte rešerši existujících nástrojů pro statickou analýzu, krokování a hledání chyb v BASH skriptech.
 - Navrhněte a implementujte nástroj, který umožní psát uživatelské skripty pro analýzu příkazů a ovlivňování jejich spouštění a vykonávání. Nástroj musí umožňovat krokovat složitější skripty po jednotlivých příkazech. Pro analýzu spouštěných skriptů využijte vhodný nástroj z rešeršní části.
 - Vytvořte ukázkové skripty pro zvrácení, či zamezení efektů základních příkazů z GNU coreutils. Zaznamenávejte jejich spouštění a umožněte jimi provedené změny vrátit do původního stavu.

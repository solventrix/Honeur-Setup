import click

from .command import commands as init_group

@click.group()
def cli_feder8():
    """Subcommand `feder8`."""
    pass

cli_feder8.add_command(init_group.init)
